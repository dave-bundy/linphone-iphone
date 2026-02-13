import Foundation
import StellarVPNSDK
import Combine

@MainActor
final class StellarVPNManager: ObservableObject {
    static let shared = StellarVPNManager()

    let vpnClient: StellarVPNClient

    @Published var latestStats: DatapathStats?
    @Published var overlayEnabled: Bool {
        didSet { UserDefaults.standard.set(overlayEnabled, forKey: "vpn_overlay_enabled") }
    }
    /// Which path the overlay should treat as "active" (delays path switch by 3s so MOS settles)
    @Published var displayActivePath: String?
    /// True when WiFi was bad enough to trigger a forced switch — overlay shows STALL indicator
    @Published var wifiStalled: Bool = false

    private var statsTimer: Timer?
    private var statusForwarder: AnyCancellable?
    private var pathSwitchCountdown: Int = 0

    // Stall detection
    private var stallConsecutiveCount: Int = 0
    private let stallThresholdSeconds: Int = 3
    private let stallThroughputMinKbps: Double = 10.0
    private var lastGoodKbpsIn: Double = 0.0
    private var stallCooldownRemaining: Int = 0

    private init() {
        self.vpnClient = StellarVPNClient(
            appGroupID: "group.com.starten.linphone",
            tunnelBundleId: "com.starten.linphone.network-extension"
        )
        self.overlayEnabled = UserDefaults.standard.bool(forKey: "vpn_overlay_enabled")

        // Configure remote log server so NE can send logs
        if let defaults = UserDefaults(suiteName: "group.com.starten.linphone") {
            defaults.set("71.174.57.22", forKey: "logServerHost")
            defaults.set(9999, forKey: "logServerPort")
        }

        // Forward vpnClient status changes so views observing StellarVPNManager re-render
        statusForwarder = vpnClient.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    // MARK: - Stats Polling

    func startStatsPolling() {
        guard statsTimer == nil else { return }
        statsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.vpnClient.status == .connected || self.vpnClient.status == .connecting else { return }
                let newStats = await self.vpnClient.fetchDatapathStats()
                // Keep last known stats visible in overlay when fetch fails
                if newStats != nil {
                    self.latestStats = newStats

                    // Delay only the active-path indicator by 3s so MOS values settle
                    let realActive = newStats?.activePath
                    if realActive != self.displayActivePath {
                        if self.displayActivePath == nil {
                            self.displayActivePath = realActive
                        } else if self.pathSwitchCountdown == 0 {
                            self.pathSwitchCountdown = 3
                        }
                    }
                    if self.pathSwitchCountdown > 0 {
                        self.pathSwitchCountdown -= 1
                        if self.pathSwitchCountdown == 0 {
                            self.displayActivePath = newStats?.activePath
                        }
                    }
                }

                // Stall detection (only while connected)
                guard self.vpnClient.status == .connected else {
                    self.stallConsecutiveCount = 0
                    self.lastGoodKbpsIn = 0
                    return
                }

                // Clear stall flag as soon as we're back on WiFi (regardless of cooldown)
                if let stats = newStats, stats.activePath == "Wi-Fi" && self.wifiStalled {
                    self.wifiStalled = false
                }

                // Cooldown: don't re-trigger stall detector for 30s after a forced switch
                if self.stallCooldownRemaining > 0 {
                    self.stallCooldownRemaining -= 1
                }

                var isStalled = false
                if self.stallCooldownRemaining == 0, let stats = newStats {
                    // Track baseline download throughput
                    if stats.kbpsIn > self.stallThroughputMinKbps {
                        self.lastGoodKbpsIn = stats.kbpsIn
                    }

                    // Only detect stalls on WiFi — after switching to Cell, let the probing handle switch-back
                    if stats.activePath == "Wi-Fi" {
                        let activePLR = stats.wifi?.packetLossPercent ?? 0
                        let downloadCollapsed = self.lastGoodKbpsIn > 20.0 && stats.kbpsIn < self.stallThroughputMinKbps
                        let highPLR = activePLR > 2.0 && (stats.kbpsIn + stats.kbpsOut) < self.stallThroughputMinKbps
                        isStalled = downloadCollapsed || highPLR
                    }
                }

                if isStalled {
                    self.stallConsecutiveCount += 1
                    if self.stallConsecutiveCount >= self.stallThresholdSeconds {
                        NSLog("[StellarVPN] [STALL_DETECT] Stall detected (count=%d, lastGoodIn=%.0f) — forcing path switch",
                              self.stallConsecutiveCount, self.lastGoodKbpsIn)
                        self.wifiStalled = true
                        Task { await self.vpnClient.forcePathSwitch() }
                        self.stallConsecutiveCount = 0
                        self.lastGoodKbpsIn = 0
                        self.stallCooldownRemaining = 30
                    }
                } else {
                    self.stallConsecutiveCount = 0
                }
            }
        }
    }

    func stopStatsPolling() {
        statsTimer?.invalidate()
        statsTimer = nil
        latestStats = nil
        displayActivePath = nil
        wifiStalled = false
        pathSwitchCountdown = 0
        stallConsecutiveCount = 0
        stallCooldownRemaining = 0
        lastGoodKbpsIn = 0
    }

    // MARK: - SIP Server Auto-Whitelist

    func autoWhitelistSIPServers() async {
        let hostnames = ["sip.linphone.org", "stun.linphone.org"]
        for hostname in hostnames {
            let ips = resolveHostname(hostname)
            for ip in ips {
                try? await vpnClient.whitelistIP(ip)
            }
        }
    }

    /// DNS-resolve a hostname to IP addresses using POSIX getaddrinfo.
    private func resolveHostname(_ hostname: String) -> [String] {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM

        var result: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(hostname, nil, &hints, &result)
        guard status == 0, let firstResult = result else { return [] }
        defer { freeaddrinfo(firstResult) }

        var ips: [String] = []
        var current: UnsafeMutablePointer<addrinfo>? = firstResult
        while let info = current {
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(info.pointee.ai_addr, info.pointee.ai_addrlen,
                           &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST) == 0 {
                let ip = String(cString: buffer)
                if !ips.contains(ip) { ips.append(ip) }
            }
            current = info.pointee.ai_next
        }
        return ips
    }
}
