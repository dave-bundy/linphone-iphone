import SwiftUI
import StellarVPNSDK

struct VPNSettingsFragment: View {

    @StateObject private var viewModel = VPNSettingsViewModel()
    @ObservedObject private var vpnManager = StellarVPNManager.shared

    @Binding var isShowVPNSettingsFragment: Bool

    @State private var connectionIsOpen: Bool = true
    @State private var routingIsOpen: Bool = false
    @State private var whitelistIsOpen: Bool = false
    @State private var displayIsOpen: Bool = false
    @State private var debugIsOpen: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 1) {
                    Rectangle()
                        .foregroundColor(Color.orangeMain500)
                        .edgesIgnoringSafeArea(.top)
                        .frame(height: 0)

                    // Header bar
                    HStack {
                        Image("caret-left")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundStyle(Color.orangeMain500)
                            .frame(width: 25, height: 25, alignment: .leading)
                            .padding(.all, 10)
                            .padding(.top, 4)
                            .padding(.leading, -10)
                            .onTapGesture {
                                withAnimation {
                                    isShowVPNSettingsFragment = false
                                }
                            }

                        Text("VPN Settings")
                            .default_text_style_orange_800(styleSize: 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                            .lineLimit(1)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    .background(.white)

                    ScrollView {
                        VStack(spacing: 0) {

                            // MARK: - Connection Section
                            sectionHeader(title: "Connection", isOpen: $connectionIsOpen)

                            if connectionIsOpen {
                                VStack(spacing: 12) {
                                    labeledTextField(label: "Gateway Address", text: $viewModel.gatewayAddress)
                                    labeledTextField(label: "TEMPID", text: $viewModel.tempID, placeholder: "Leave empty if not provisioned")

                                    // Bonding Mode Picker
                                    HStack {
                                        Text("Bonding Mode")
                                            .default_text_style(styleSize: 14)
                                        Spacer()
                                        Picker("", selection: $viewModel.selectedBondingMode) {
                                            Text("Opt. Latency").tag(BondingMode.optimizedLatency)
                                            Text("Opt. Throughput").tag(BondingMode.optimizedThroughput)
                                            Text("Resiliency").tag(BondingMode.resiliency)
                                            Text("WiFi Steering").tag(BondingMode.wifiSteering)
                                            Text("No Bond").tag(BondingMode.noBond)
                                        }
                                        .pickerStyle(.menu)
                                        .tint(Color.orangeMain500)
                                    }

                                    // Status
                                    HStack {
                                        Text("Status:")
                                            .default_text_style(styleSize: 14)
                                        Circle()
                                            .fill(statusColor)
                                            .frame(width: 10, height: 10)
                                        Text(viewModel.statusText)
                                            .default_text_style(styleSize: 14)
                                        Spacer()
                                    }

                                    // Error message
                                    if let error = viewModel.errorMessage {
                                        Text(error)
                                            .foregroundStyle(.red)
                                            .font(.system(size: 12))
                                    }

                                    // Connect/Disconnect button
                                    Button(action: {
                                        if vpnManager.vpnClient.status == .connected {
                                            viewModel.disconnect()
                                        } else {
                                            viewModel.connect()
                                        }
                                    }) {
                                        HStack {
                                            if viewModel.isConnecting {
                                                ProgressView()
                                                    .tint(.white)
                                                    .padding(.trailing, 4)
                                            }
                                            Text(vpnManager.vpnClient.status == .connected ? "Disconnect" : "Connect")
                                                .foregroundStyle(.white)
                                                .font(.body.weight(.semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(vpnManager.vpnClient.status == .connected ? Color.red : Color.orangeMain500)
                                        .cornerRadius(10)
                                    }
                                    .disabled(viewModel.isConnecting)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.white)
                            }

                            // MARK: - Routing Section
                            sectionHeader(title: "Routing", isOpen: $routingIsOpen)

                            if routingIsOpen {
                                VStack(spacing: 12) {
                                    Toggle("Blacklist Mode (all traffic)", isOn: $viewModel.blacklistMode)
                                        .tint(Color.orangeMain500)

                                    Text("OFF = whitelist mode (only whitelisted IPs through VPN)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.white)
                            }

                            // MARK: - Whitelisted IPs Section
                            sectionHeader(title: "Whitelisted IPs", isOpen: $whitelistIsOpen)

                            if whitelistIsOpen {
                                VStack(spacing: 8) {
                                    ForEach(viewModel.whitelistedIPs, id: \.self) { ip in
                                        HStack {
                                            Text(ip)
                                                .font(.system(size: 13, design: .monospaced))
                                            Spacer()
                                            Button(action: { viewModel.removeWhitelistedIP(ip) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.gray)
                                            }
                                        }
                                    }

                                    if viewModel.whitelistedIPs.isEmpty {
                                        Text("No IPs whitelisted yet")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.gray)
                                    }

                                    HStack {
                                        TextField("IP address", text: $viewModel.newIPText)
                                            .font(.system(size: 13, design: .monospaced))
                                            .textFieldStyle(.roundedBorder)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)

                                        Button("Add") {
                                            viewModel.addWhitelistedIP()
                                        }
                                        .foregroundStyle(Color.orangeMain500)
                                        .disabled(viewModel.newIPText.trimmingCharacters(in: .whitespaces).isEmpty)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.white)
                            }

                            // MARK: - Display Section
                            sectionHeader(title: "Display", isOpen: $displayIsOpen)

                            if displayIsOpen {
                                VStack(spacing: 12) {
                                    Toggle("Show stats overlay during calls", isOn: $viewModel.overlayEnabled)
                                        .tint(Color.orangeMain500)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.white)
                            }

                            // MARK: - Debug Section
                            sectionHeader(title: "Debug", isOpen: $debugIsOpen)

                            if debugIsOpen {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Log Server")
                                            .default_text_style(styleSize: 14)
                                        Spacer()
                                        TextField("host", text: $viewModel.logServerHost)
                                            .font(.system(size: 13, design: .monospaced))
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 140)
                                            .autocapitalization(.none)
                                        Text(":")
                                        TextField("port", text: $viewModel.logServerPort)
                                            .font(.system(size: 13, design: .monospaced))
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 60)
                                            .keyboardType(.numberPad)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.white)
                            }
                        }
                    }
                    .background(Color.gray100)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear {
            viewModel.refreshWhitelist()
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch vpnManager.vpnClient.status {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        default: return .red
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, isOpen: Binding<Bool>) -> some View {
        Button(action: { withAnimation { isOpen.wrappedValue.toggle() } }) {
            HStack {
                Image(systemName: isOpen.wrappedValue ? "chevron.down" : "chevron.right")
                    .foregroundStyle(Color.orangeMain500)
                    .frame(width: 16)
                Text(title)
                    .default_text_style_orange_800(styleSize: 14)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.gray100)
        }
    }

    @ViewBuilder
    private func labeledTextField(label: String, text: Binding<String>, placeholder: String = "") -> some View {
        HStack {
            Text(label)
                .default_text_style(styleSize: 14)
                .frame(width: 120, alignment: .leading)
            TextField(placeholder.isEmpty ? label : placeholder, text: text)
                .font(.system(size: 13, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
}
