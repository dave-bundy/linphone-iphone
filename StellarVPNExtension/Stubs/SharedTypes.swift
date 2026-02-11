//
//  SharedTypes.swift
//  StellarVPNExtension
//
//  Stub implementations of types defined in the StartenSMART main app module.
//  These provide the same interface with no-op/in-memory implementations so
//  the Network Extension target compiles standalone.
//

import Foundation
import CoreLocation
import UIKit
import SystemConfiguration

// MARK: - CaptiveNetwork Compatibility Shims
// CNCopySupportedInterfaces/CNCopyCurrentNetworkInfo were removed in iOS 26 SDK.
// Provide stub functions so symlinked code that references them still compiles.

func CNCopySupportedInterfaces() -> CFArray? { return nil }
func CNCopyCurrentNetworkInfo(_ interfaceName: CFString) -> CFDictionary? { return nil }
let kCNNetworkInfoKeyBSSID: CFString = "BSSID" as CFString

// MARK: - LogLevel

enum LogLevel: String, Codable {
    case debug, info, warning, error, critical
}

// MARK: - InterfaceTrafficData

struct InterfaceTrafficData: Codable {
    var pathSrtt: UInt64?
    var packetLoss: Double?
}

// MARK: - InterfaceStatus

struct InterfaceStatus: Codable {
    var wifi: Bool?
    var cellular: Bool?
}

// MARK: - LoginState

enum LoginState: String {
    case phone
    case email
    case google
    case apple
    case unknown
    case anonymous
    case none
}

// MARK: - CodableLocation

struct CodableLocation: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: CLLocationDistance
    let horizontalAccuracy: CLLocationAccuracy
    let verticalAccuracy: CLLocationAccuracy
    let speed: CLLocationSpeed
    let course: CLLocationDirection
    let timestamp: Date

    init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.speed = location.speed
        self.course = location.course
        self.timestamp = location.timestamp
    }

    var asCLLocation: CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            speed: speed,
            timestamp: timestamp
        )
    }
}

// MARK: - UserDefaultsManagerProtocol

protocol UserDefaultsManagerProtocol {
    var connectAtStartup: Bool { get set }
    var useReliableMode: Bool { get set }
    var ipAddress: String { get set }
    var ipv6Address: String { get set }
    var bondingMode: String { get set }
    var isVPNConfigured: Bool { get set }
    var lastLocation: CLLocation? { get set }
    var lastEnableWifiNotifiedTime: Date? { get set }
    var lastIPListFetched: Date? { get set }
    var appState: UIApplication.State { get set }
    var isWhiteList: Bool { get set }
    var isInterfaceSwitchEnabled: Bool { get set }
    var provisionedSSIDs: [String] { get set }
    var codableLocation: CodableLocation? { get set }
    var loginState: LoginState { get set }
    var loginIdentifier: String? { get set }
    var fcmToken: String? { get set }
    var tunnelRemoteAddress: String { get set }
    var tunnelAddressIPv4: String { get set }
    var tunnelAddressIPv6: String { get set }
    var currentPath: String { get set }
    var deviceID: String { get set }
    var vpnlastStopReason: Int { get set }
    var shareLogsToggle: Bool { get set }
    var nativeLibVersion: String? { get set }
    var interfaceInfo: [String: String] { get set }
    var currentInterfacePath: Int { get set }
    var interfaceStatus: InterfaceStatus { get set }
    var wifiData: InterfaceTrafficData { get set }
    var cellularData: InterfaceTrafficData { get set }
    var isUserInsideGeofence: Bool { get set }
    var manualStartCount: Int { get set }
    var manualStopCount: Int { get set }
    var totalStartCount: Int { get set }
    var autoStopCount: [CloseConnErrorCode: Int] { get set }
    var vpnStartTimeStamp: Date? { get set }
    var receivedSilentPush: Bool { get set }
    var isWifiConnected: Bool { get set }
    var isCellularConnected: Bool { get set }
    var isXQuicRunning: Bool { get set }
    var isCoolDownTimerRunning: Bool { get set }
    var coolDownStartTime: Date? { get set }
    var wifiPathStatus: Int { get set }
    var cellularPathStatus: Int { get set }
    var activeServer: String { get set }
    var didUserToggleDownButton: Bool { get set }
    var rcShouldShowWifiPopup: Bool { get set }
    var rcRequestLocationPermission: Bool { get set }

    func increment(_ code: CloseConnErrorCode)
}

// MARK: - UserDefaultsManager (App Group backed)

class UserDefaultsManager: UserDefaultsManagerProtocol {
    static let shared = UserDefaultsManager()

    private let defaults = UserDefaults(suiteName: "group.com.starten.linphone")!

    private init() {}

    // MARK: - Keys
    private enum Keys {
        static let connectAtStartup = "connectAtStartup"
        static let useReliableMode = "useReliableMode"
        static let ipAddress = "ipAddress"
        static let ipv6Address = "ipv6Address"
        static let bondingMode = "bondingMode"
        static let isVPNConfigured = "isVPNConfigured"
        static let lastLocation = "lastLocation"
        static let lastEnableWifiNotifiedTime = "lastEnableWifiNotifiedTime"
        static let lastIPListFetched = "lastIPListFetched"
        static let appState = "appState"
        static let isWhiteList = "isWhiteList"
        static let isInterfaceSwitchEnabled = "isInterfaceSwitchEnabled"
        static let provisionedSSids = "provisionedSSids"
        static let codableLocation = "codableLocation"
        static let loginState = "loginState"
        static let loginIdentifier = "loginIdentifier"
        static let fcmToken = "fcmToken"
        static let tunnelRemoteAddress = "tunnelRemoteAddress"
        static let tunnelAddressIPv4 = "tunnelAddressIPv4"
        static let tunnelAddressIPv6 = "tunnelAddressIPv6"
        static let currentPath = "currentPath"
        static let deviceID = "deviceID"
        static let vpnlastStopReason = "vpnlastStopReason"
        static let shareLogsToggle = "shareLogsToggle"
        static let nativeLibVersion = "D1.0.0_000B_12-11-2025"
        static let interfaceInfo = "interfaceInfo"
        static let currentInterfacePath = "currentInterfacePath"
        static let interfaceStatus = "interfaceStatus"
        static let wifiData = "wifiData"
        static let cellularData = "cellularData"
        static let isUserInsideGeofence = "isUserInsideGeofence"
        static let manualStartCount = "manualStartCount"
        static let manualStopCount = "manualStopCount"
        static let totalStartCount = "totalStartCount"
        static let autoStopCount = "autoStopCount"
        static let vpnStartTimeStamp = "vpnStartTimeStamp"
        static let receivedSilentPush = "receivedSilentPush"
        static let isWifiConnected = "isWifiConnected"
        static let isCellularConnected = "isCellularConnected"
        static let isXQuicRunning = "isXQuicRunning"
        static let isCoolDownTimerRunning = "isCoolDownTimerRunning"
        static let coolDownStartTime = "coolDownStartTime"
        static let wifiPathStatus = "wifiPathStatus"
        static let cellularPathStatus = "cellularPathStatus"
        static let activeServer = "activeServer"
        static let rcShouldShowWifiPopup = "rcShouldShowWifiPopup"
        static let rcRequestLocationPermission = "rcRequestLocationPermission"
        static let didUserToggleDownButton = "didUserToggleDownButton"
    }

    // MARK: - Accessors

    var connectAtStartup: Bool {
        get { defaults.bool(forKey: Keys.connectAtStartup) }
        set { defaults.set(newValue, forKey: Keys.connectAtStartup) }
    }

    var useReliableMode: Bool {
        get { defaults.bool(forKey: Keys.useReliableMode) }
        set { defaults.set(newValue, forKey: Keys.useReliableMode) }
    }

    var ipAddress: String {
        get { defaults.string(forKey: Keys.ipAddress) ?? "" }
        set { defaults.set(newValue, forKey: Keys.ipAddress) }
    }

    var ipv6Address: String {
        get { defaults.string(forKey: Keys.ipv6Address) ?? "" }
        set { defaults.set(newValue, forKey: Keys.ipv6Address) }
    }

    var bondingMode: String {
        get { defaults.string(forKey: Keys.bondingMode) ?? "3" }
        set { defaults.set(newValue, forKey: Keys.bondingMode) }
    }

    var isVPNConfigured: Bool {
        get { defaults.bool(forKey: Keys.isVPNConfigured) }
        set { defaults.set(newValue, forKey: Keys.isVPNConfigured) }
    }

    var lastLocation: CLLocation? {
        get {
            if let data = defaults.data(forKey: Keys.lastLocation),
               let location = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CLLocation {
                return location
            }
            return nil
        }
        set {
            if let location = newValue {
                let data = try? NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: false)
                defaults.set(data, forKey: Keys.lastLocation)
            } else {
                defaults.removeObject(forKey: Keys.lastLocation)
            }
        }
    }

    var lastEnableWifiNotifiedTime: Date? {
        get { defaults.object(forKey: Keys.lastEnableWifiNotifiedTime) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastEnableWifiNotifiedTime) }
    }

    var lastIPListFetched: Date? {
        get { defaults.object(forKey: Keys.lastIPListFetched) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastIPListFetched) }
    }

    var appState: UIApplication.State {
        get {
            if let rawValue = defaults.value(forKey: Keys.appState) as? Int,
               let state = UIApplication.State(rawValue: rawValue) {
                return state
            }
            return .inactive
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.appState) }
    }

    var isWhiteList: Bool {
        get { defaults.bool(forKey: Keys.isWhiteList) }
        set { defaults.set(newValue, forKey: Keys.isWhiteList) }
    }

    var isInterfaceSwitchEnabled: Bool {
        get { defaults.bool(forKey: Keys.isInterfaceSwitchEnabled) }
        set { defaults.set(newValue, forKey: Keys.isInterfaceSwitchEnabled) }
    }

    var provisionedSSIDs: [String] {
        get { defaults.stringArray(forKey: Keys.provisionedSSids) ?? [] }
        set { defaults.set(newValue, forKey: Keys.provisionedSSids) }
    }

    var codableLocation: CodableLocation? {
        get {
            guard let data = defaults.data(forKey: Keys.codableLocation) else { return nil }
            return try? JSONDecoder().decode(CodableLocation.self, from: data)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                defaults.set(encoded, forKey: Keys.codableLocation)
            }
        }
    }

    var loginState: LoginState {
        get {
            let rawValue = defaults.string(forKey: Keys.loginState) ?? LoginState.unknown.rawValue
            return LoginState(rawValue: rawValue) ?? .unknown
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.loginState) }
    }

    var loginIdentifier: String? {
        get { defaults.string(forKey: Keys.loginIdentifier) }
        set { defaults.set(newValue, forKey: Keys.loginIdentifier) }
    }

    var fcmToken: String? {
        get { defaults.string(forKey: Keys.fcmToken) }
        set { defaults.set(newValue, forKey: Keys.fcmToken) }
    }

    var tunnelRemoteAddress: String {
        get { defaults.string(forKey: Keys.tunnelRemoteAddress) ?? "11.200.0.1" }
        set { defaults.set(newValue, forKey: Keys.tunnelRemoteAddress) }
    }

    var tunnelAddressIPv4: String {
        get { defaults.string(forKey: Keys.tunnelAddressIPv4) ?? "" }
        set { defaults.set(newValue, forKey: Keys.tunnelAddressIPv4) }
    }

    var tunnelAddressIPv6: String {
        get { defaults.string(forKey: Keys.tunnelAddressIPv6) ?? "" }
        set { defaults.set(newValue, forKey: Keys.tunnelAddressIPv6) }
    }

    var currentPath: String {
        get { defaults.string(forKey: Keys.currentPath) ?? "" }
        set { defaults.set(newValue, forKey: Keys.currentPath) }
    }

    var deviceID: String {
        get { defaults.string(forKey: Keys.deviceID) ?? "" }
        set { defaults.set(newValue, forKey: Keys.deviceID) }
    }

    var vpnlastStopReason: Int {
        get { defaults.integer(forKey: Keys.vpnlastStopReason) }
        set { defaults.set(newValue, forKey: Keys.vpnlastStopReason) }
    }

    var shareLogsToggle: Bool {
        get { defaults.bool(forKey: Keys.shareLogsToggle) }
        set { defaults.set(newValue, forKey: Keys.shareLogsToggle) }
    }

    var nativeLibVersion: String? {
        get { defaults.string(forKey: Keys.nativeLibVersion) ?? "" }
        set { defaults.set(newValue, forKey: Keys.nativeLibVersion) }
    }

    var interfaceInfo: [String: String] {
        get { defaults.dictionary(forKey: Keys.interfaceInfo) as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: Keys.interfaceInfo) }
    }

    var currentInterfacePath: Int {
        get { defaults.integer(forKey: Keys.currentInterfacePath) }
        set { defaults.set(newValue, forKey: Keys.currentInterfacePath) }
    }

    var interfaceStatus: InterfaceStatus {
        get {
            guard let data = defaults.data(forKey: Keys.interfaceStatus),
                  let decoded = try? PropertyListDecoder().decode(InterfaceStatus.self, from: data) else {
                return InterfaceStatus(wifi: false, cellular: false)
            }
            return decoded
        }
        set {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            if let encoded = try? encoder.encode(newValue) {
                defaults.set(encoded, forKey: Keys.interfaceStatus)
            }
        }
    }

    var wifiData: InterfaceTrafficData {
        get {
            guard let data = defaults.data(forKey: Keys.wifiData),
                  let decoded = try? PropertyListDecoder().decode(InterfaceTrafficData.self, from: data) else {
                return InterfaceTrafficData(pathSrtt: 0, packetLoss: 0)
            }
            return decoded
        }
        set {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            if let encoded = try? encoder.encode(newValue) {
                defaults.set(encoded, forKey: Keys.wifiData)
            }
        }
    }

    var cellularData: InterfaceTrafficData {
        get {
            guard let data = defaults.data(forKey: Keys.cellularData),
                  let decoded = try? PropertyListDecoder().decode(InterfaceTrafficData.self, from: data) else {
                return InterfaceTrafficData(pathSrtt: 0, packetLoss: 0)
            }
            return decoded
        }
        set {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            if let encoded = try? encoder.encode(newValue) {
                defaults.set(encoded, forKey: Keys.cellularData)
            }
        }
    }

    var isUserInsideGeofence: Bool {
        get { defaults.bool(forKey: Keys.isUserInsideGeofence) }
        set { defaults.set(newValue, forKey: Keys.isUserInsideGeofence) }
    }

    var manualStartCount: Int {
        get { defaults.integer(forKey: Keys.manualStartCount) }
        set { defaults.set(newValue, forKey: Keys.manualStartCount) }
    }

    var manualStopCount: Int {
        get { defaults.integer(forKey: Keys.manualStopCount) }
        set { defaults.set(newValue, forKey: Keys.manualStopCount) }
    }

    var totalStartCount: Int {
        get { defaults.integer(forKey: Keys.totalStartCount) }
        set { defaults.set(newValue, forKey: Keys.totalStartCount) }
    }

    var autoStopCount: [CloseConnErrorCode: Int] {
        get {
            guard let dict = defaults.dictionary(forKey: Keys.autoStopCount) as? [String: Int] else {
                return Dictionary(uniqueKeysWithValues: CloseConnErrorCode.allCases.map { ($0, 0) })
            }
            var result: [CloseConnErrorCode: Int] = [:]
            for code in CloseConnErrorCode.allCases {
                result[code] = dict["\(code.rawValue)"] ?? 0
            }
            return result
        }
        set {
            let dict = Dictionary(uniqueKeysWithValues: newValue.map { ("\($0.key.rawValue)", $0.value) })
            defaults.set(dict, forKey: Keys.autoStopCount)
        }
    }

    var vpnStartTimeStamp: Date? {
        get { defaults.object(forKey: Keys.vpnStartTimeStamp) as? Date }
        set { defaults.set(newValue, forKey: Keys.vpnStartTimeStamp) }
    }

    var receivedSilentPush: Bool {
        get { defaults.bool(forKey: Keys.receivedSilentPush) }
        set { defaults.set(newValue, forKey: Keys.receivedSilentPush) }
    }

    var isWifiConnected: Bool {
        get { defaults.bool(forKey: Keys.isWifiConnected) }
        set { defaults.set(newValue, forKey: Keys.isWifiConnected) }
    }

    var isCellularConnected: Bool {
        get { defaults.bool(forKey: Keys.isCellularConnected) }
        set { defaults.set(newValue, forKey: Keys.isCellularConnected) }
    }

    var isXQuicRunning: Bool {
        get { defaults.bool(forKey: Keys.isXQuicRunning) }
        set { defaults.set(newValue, forKey: Keys.isXQuicRunning) }
    }

    var isCoolDownTimerRunning: Bool {
        get { defaults.bool(forKey: Keys.isCoolDownTimerRunning) }
        set { defaults.set(newValue, forKey: Keys.isCoolDownTimerRunning) }
    }

    var coolDownStartTime: Date? {
        get { defaults.object(forKey: Keys.coolDownStartTime) as? Date }
        set { defaults.set(newValue, forKey: Keys.coolDownStartTime) }
    }

    var wifiPathStatus: Int {
        get { defaults.integer(forKey: Keys.wifiPathStatus) }
        set { defaults.set(newValue, forKey: Keys.wifiPathStatus) }
    }

    var cellularPathStatus: Int {
        get { defaults.integer(forKey: Keys.cellularPathStatus) }
        set { defaults.set(newValue, forKey: Keys.cellularPathStatus) }
    }

    var activeServer: String {
        get { defaults.string(forKey: Keys.activeServer) ?? "" }
        set { defaults.set(newValue, forKey: Keys.activeServer) }
    }

    var didUserToggleDownButton: Bool {
        get { defaults.bool(forKey: Keys.didUserToggleDownButton) }
        set { defaults.set(newValue, forKey: Keys.didUserToggleDownButton) }
    }

    var rcShouldShowWifiPopup: Bool {
        get { defaults.bool(forKey: Keys.rcShouldShowWifiPopup) }
        set { defaults.set(newValue, forKey: Keys.rcShouldShowWifiPopup) }
    }

    var rcRequestLocationPermission: Bool {
        get { defaults.bool(forKey: Keys.rcRequestLocationPermission) }
        set { defaults.set(newValue, forKey: Keys.rcRequestLocationPermission) }
    }

    func increment(_ code: CloseConnErrorCode) {
        var counts = autoStopCount
        counts[code] = (counts[code] ?? 0) + 1
        autoStopCount = counts
    }

    func updateInterfaceInfo(key: Int, value: String) {
        var dict = interfaceInfo
        dict["\(key)"] = value
        interfaceInfo = dict
    }

    func removeInterfaceInfo(key: Int) {
        var dict = interfaceInfo
        dict.removeValue(forKey: "\(key)")
        interfaceInfo = dict
    }

    func resetInterfaceInfo() {
        defaults.removeObject(forKey: Keys.interfaceInfo)
        defaults.removeObject(forKey: Keys.currentInterfacePath)
    }
}

// MARK: - SharedFileManaging + SharedFileManager (no-op stub)

protocol SharedFileManaging {
    func save<T: Codable>(_ object: T, to fileName: String) async -> Bool
    func saveRaw(_ data: Data, to fileName: String) async -> Bool
    func load<T: Codable>(_ type: T.Type, from fileName: String) async -> T?
    func loadRaw(from fileName: String) async -> Data?
    func fileURL(for fileName: String) -> URL?
    func fileExists(_ fileName: String) -> Bool
    func fileURLIfExists(_ fileName: String) -> URL?
    func delete(_ fileName: String)
    func getCompressedFile(_ fileName: [String]) -> URL?
}

final class SharedFileManager: SharedFileManaging {
    static let shared = SharedFileManager()
    private init() {}

    @discardableResult
    func save<T: Codable>(_ object: T, to fileName: String) async -> Bool { return false }
    func saveRaw(_ data: Data, to fileName: String) async -> Bool { return false }
    func load<T: Codable>(_ type: T.Type, from fileName: String) async -> T? { return nil }
    func loadRaw(from fileName: String) async -> Data? { return nil }
    func fileURL(for fileName: String) -> URL? { return nil }
    func fileExists(_ fileName: String) -> Bool { return false }
    func fileURLIfExists(_ fileName: String) -> URL? { return nil }
    func delete(_ fileName: String) {}
    func getCompressedFile(_ fileName: [String]) -> URL? { return nil }
}

// MARK: - NetworkConstants

enum NetworkConstants {
    static let serverPort = 51000
    static let locationWebSocketPort = 3001
    static let smartDataWebSocketPort = 4002
    static let notificationPort = 3001
    static let defaultMTU: NSNumber = 1360
    static let frameSizeLimit = 1500
    static let quicPacketSize = 1400
    static let subnetMask = "255.255.255.0"
    static let fullSubnetMask = "255.255.255.255"
    static let defaultDNS = "8.8.8.8"
    static let ipv6PrefixLength: NSNumber = 120
    static let wifiTimeoutSeconds: TimeInterval = 6
    static let urlRequestTimeout: TimeInterval = 5
}

// MARK: - NetworkPolicyManager (stub)

final class NetworkPolicyManager {
    static let shared = NetworkPolicyManager()
    private init() {}

    func networkVersion() -> Int32? { return 4 }
    func currentServerAddress() -> String? { return nil }
    func refreshPolicyNow() -> String? { return nil }
    func isWiFiAvailable() -> Bool { return false }
    func isCellularAvailable() -> Bool { return false }
}

// MARK: - NewPolicy + ExcludeIPs

struct ExcludeIPs: Codable {
    let domain: String?
    let ipv4: [String]?
    let ipv6: [String]?
}

struct NewPolicy: Codable {
    let wifiRssiThreshold: Int?
    let isAllowed: Bool?
    let appSelection: String?
    let appList: [ExcludeIPs]
    let provisionedSSIDs: [String]
    let bondingMode: Int?
    let minWifiPacketLossThreshold: Double?
    let maxWifiPacketLossThreshold: Double?
    let maxCellPacketLossThreshold: Double?
    let wifiToCellSrttDeltaMs: Int?
    let cellToWifiSrttDeltaMs: Int?
    let cooldownTimerSec: Int?
    let smoothingFactorAlpha: Double?

    enum CodingKeys: String, CodingKey {
        case wifiRssiThreshold
        case isAllowed
        case appList
        case appSelection
        case provisionedSSIDs = "ProvisionedSSIDs"
        case bondingMode
        case minWifiPacketLossThreshold
        case maxWifiPacketLossThreshold
        case maxCellPacketLossThreshold
        case wifiToCellSrttDeltaMs
        case cellToWifiSrttDeltaMs
        case cooldownTimerSec
        case smoothingFactorAlpha
    }
}

// MARK: - AppLogger (stub - prints to console)

final class AppLogger {
    static let shared = AppLogger()
    private init() {}

    func log(_ tag: String, level: LogLevel, _ message: String) {
        NSLog("[\(level.rawValue.uppercased())] \(tag): \(message)")
    }
}

// MARK: - webSocketEventMethods (no-op stub)

struct webSocketEventMethods {
    static func sendEventToLocationEndpoint(_ event: String, _ reason: String) async {
        // no-op
    }
}

// MARK: - TR069Manager (no-op stub)

class TR069Manager {
    static let shared = TR069Manager()
    private init() {}

    func sendOnce() async {
        // no-op
    }
}

// MARK: - NetworkConfig + HTTPMethod + NetworkError

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
}

struct NetworkConfig {
    let url: URL
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?

    init(url: URL, method: HTTPMethod = .get, headers: [String: String] = [:], body: Data? = nil) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
}

enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case statusCode(Int)
    case decodingError(Error)
}

// MARK: - NetworkManager (stub using URLSession)

protocol NetworkManaging {
    func send<T: Decodable>(_ config: NetworkConfig, authToken: String?, expectRawResponse: Bool) async throws -> T
}

extension NetworkManaging {
    func send<T: Decodable>(_ config: NetworkConfig) async throws -> T {
        try await send(config, authToken: nil, expectRawResponse: false)
    }
}

final class NetworkManager: NetworkManaging {
    static var shared: NetworkManaging = NetworkManager()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send<T: Decodable>(_ config: NetworkConfig, authToken: String? = nil, expectRawResponse: Bool = false) async throws -> T {
        var request = URLRequest(url: config.url)
        request.httpMethod = config.method.rawValue
        request.allHTTPHeaderFields = config.headers
        request.timeoutInterval = 15
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = config.body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.statusCode(httpResponse.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

// MARK: - CFNotificationCenterManager + NotificationType (stub)

enum NotificationType: String {
    case vpnConnected        = "com.stellar.vpn.connected"
    case vpnDisconnected     = "com.stellar.vpn.disconnected"
    case clientDeprovisioned = "com.stellar.vpn.clientDeprovisioned"
    case tunnelIPNotFound    = "com.stellar.vpn.tunnelIPNotFound"
}

final class CFNotificationCenterManager {
    static let shared = CFNotificationCenterManager()
    private init() {}

    static func sendCFNotification(notificationType: NotificationType) {
        let cfName = notificationType.rawValue as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(cfName),
            nil, nil, true
        )
    }

    func observeCFNotification(for notificationType: NotificationType, _ callback: @escaping () -> Void) {
        // no-op stub
    }
}

// MARK: - WebSocketManager (no-op stub)

final class WebSocketManager {
    static let shared = WebSocketManager()
    private init() {}

    func connect(to url: URL) {}
    func send(to url: URL, text: String) {}
    func disconnect(from url: URL) {}
    func disconnectAll() {}
    func resumeAllReconnections() {}
}

// MARK: - WebSocketEventQueue (no-op stub)

final class WebSocketEventQueue {
    static let shared = WebSocketEventQueue()
    private init() {}

    func enqueue(url: URL, message: String) {}
    func flushQueue(sendHandler: @escaping (URL, String) -> Void) {}
    func isCurrentlyFlushing() -> Bool { return false }
    func queueSize() async -> Int { return 0 }
    func clearQueue() async {}
}
