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

    private var statsTimer: Timer?
    private var statusForwarder: AnyCancellable?

    // Stall detection
    private var stallConsecutiveCount: Int = 0
    private let stallThresholdSeconds: Int = 5
    private let stallThroughputMinKbps: Double = 10.0

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
                }

                // Stall detection (only while connected)
                guard self.vpnClient.status == .connected else {
                    self.stallConsecutiveCount = 0
                    return
                }

                var isStalled = false
                if let stats = newStats {
                    let activePLR: Double
                    if stats.activePath == "Wi-Fi" {
                        activePLR = stats.wifi?.packetLossPercent ?? 0
                    } else {
                        activePLR = stats.cellular?.packetLossPercent ?? 0
                    }
                    let totalKbps = stats.kbpsIn + stats.kbpsOut
                    isStalled = activePLR > 5.0 && totalKbps < self.stallThroughputMinKbps
                } else {
                    // Nil stats while connected = NE unreachable = likely stalled
                    isStalled = true
                }

                if isStalled {
                    self.stallConsecutiveCount += 1
                    if self.stallConsecutiveCount >= self.stallThresholdSeconds {
                        NSLog("[StellarVPN] [STALL_DETECT] Stall detected (count=%d, stats=%@) — forcing path switch",
                              self.stallConsecutiveCount, newStats == nil ? "nil" : "low")
                        Task { await self.vpnClient.forcePathSwitch() }
                        self.stallConsecutiveCount = 0
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
        stallConsecutiveCount = 0
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
