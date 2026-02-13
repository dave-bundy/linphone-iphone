import Foundation
import StellarVPNSDK
import Combine

@MainActor
final class VPNSettingsViewModel: ObservableObject {
    @Published var gatewayAddress: String {
        didSet { UserDefaults.standard.set(gatewayAddress, forKey: "vpn_gateway_address") }
    }
    @Published var tempID: String {
        didSet { UserDefaults.standard.set(tempID, forKey: "vpn_temp_id") }
    }
    @Published var selectedBondingMode: BondingMode {
        didSet { UserDefaults.standard.set(selectedBondingMode.rawValue, forKey: "vpn_bonding_mode") }
    }
    @Published var blacklistMode: Bool {
        didSet { UserDefaults.standard.set(blacklistMode, forKey: "vpn_blacklist_mode") }
    }
    @Published var overlayEnabled: Bool {
        didSet { StellarVPNManager.shared.overlayEnabled = overlayEnabled }
    }
    @Published var logServerHost: String {
        didSet { UserDefaults.standard.set(logServerHost, forKey: "vpn_log_server") }
    }
    @Published var logServerPort: String {
        didSet { UserDefaults.standard.set(logServerPort, forKey: "vpn_log_server_port") }
    }
    @Published var logLevel: Int {
        didSet {
            UserDefaults.standard.set(logLevel, forKey: "vpn_log_level")
            Task { await manager.vpnClient.setLogLevel(logLevel) }
        }
    }

    @Published var whitelistedIPs: [String] = []
    @Published var newIPText: String = ""
    @Published var isConnecting: Bool = false
    @Published var errorMessage: String?

    private var statusCancellable: AnyCancellable?
    private let manager = StellarVPNManager.shared

    init() {
        let defaults = UserDefaults.standard
        self.gatewayAddress = defaults.string(forKey: "vpn_gateway_address") ?? "71.174.57.22"
        self.tempID = defaults.string(forKey: "vpn_temp_id") ?? ""
        self.selectedBondingMode = BondingMode(rawValue: defaults.integer(forKey: "vpn_bonding_mode")) ?? .wifiSteering
        self.blacklistMode = defaults.bool(forKey: "vpn_blacklist_mode")
        self.overlayEnabled = StellarVPNManager.shared.overlayEnabled
        self.logServerHost = defaults.string(forKey: "vpn_log_server") ?? "71.174.57.22"
        self.logServerPort = defaults.string(forKey: "vpn_log_server_port") ?? "9999"
        self.logLevel = defaults.object(forKey: "vpn_log_level") as? Int ?? 2

        refreshWhitelist()
    }

    var vpnStatus: ConnectionStatus {
        manager.vpnClient.status
    }

    var statusText: String {
        switch vpnStatus {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .reconnecting: return "Reconnecting..."
        case .disconnecting: return "Disconnecting..."
        case .failed(let msg): return "Failed: \(msg)"
        }
    }

    var statusColor: String {
        switch vpnStatus {
        case .connected: return "green"
        case .connecting, .reconnecting: return "orange"
        default: return "red"
        }
    }

    // MARK: - Actions

    func connect() {
        guard !isConnecting else { return }
        isConnecting = true
        errorMessage = nil

        Task {
            do {
                manager.vpnClient.setGatewayAddress(gatewayAddress)
                if !tempID.isEmpty {
                    manager.vpnClient.setTempID(tempID)
                }
                manager.vpnClient.setBondingMode(selectedBondingMode)
                try await manager.vpnClient.setBlacklistMode(blacklistMode)

                // Auto-whitelist SIP servers before connecting
                await manager.autoWhitelistSIPServers()

                try await manager.vpnClient.start()

                // Configure log server and log level
                if let port = Int(logServerPort) {
                    await manager.vpnClient.setLogServer(host: logServerHost, port: port)
                }
                await manager.vpnClient.setLogLevel(logLevel)

                refreshWhitelist()
            } catch {
                errorMessage = error.localizedDescription
            }
            isConnecting = false
        }
    }

    func disconnect() {
        Task {
            await manager.vpnClient.stop()
        }
    }

    func addWhitelistedIP() {
        let ip = newIPText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ip.isEmpty else { return }
        Task {
            try? await manager.vpnClient.whitelistIP(ip)
            newIPText = ""
            refreshWhitelist()
        }
    }

    func removeWhitelistedIP(_ ip: String) {
        Task {
            try? await manager.vpnClient.removeWhitelistedIP(ip)
            refreshWhitelist()
        }
    }

    func refreshWhitelist() {
        Task {
            whitelistedIPs = await manager.vpnClient.getWhitelistedIPs()
        }
    }
}
