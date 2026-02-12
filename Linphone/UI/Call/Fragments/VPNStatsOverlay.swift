import SwiftUI
import StellarVPNSDK

struct VPNStatsOverlay: View {
    @ObservedObject var vpnManager: StellarVPNManager
    @ObservedObject var callStatsModel: CallStatsModel
    var qualityValue: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // VPN path stats
            if let stats = vpnManager.latestStats {
                pathRow(
                    label: "WiFi",
                    pathStats: stats.wifi,
                    isActive: stats.activePath == "Wi-Fi",
                    activeColor: .blue,
                    kbpsIn: stats.activePath == "Wi-Fi" ? stats.kbpsIn : nil,
                    kbpsOut: stats.activePath == "Wi-Fi" ? stats.kbpsOut : nil
                )
                pathRow(
                    label: "Cell",
                    pathStats: stats.cellular,
                    isActive: stats.activePath == "Cellular",
                    activeColor: .orange,
                    kbpsIn: stats.activePath == "Cellular" ? stats.kbpsIn : nil,
                    kbpsOut: stats.activePath == "Cellular" ? stats.kbpsOut : nil
                )
            }

            // Linphone call quality stats
            if !callStatsModel.audioCodec.isEmpty {
                Divider().background(.white.opacity(0.3))

                // MOS quality score
                HStack(spacing: 6) {
                    Circle()
                        .fill(mosColor)
                        .frame(width: 10, height: 10)
                    Text(String(format: "Audio MOS: %.1f/5.0", qualityValue))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }

                statLine(callStatsModel.audioCodec)
                statLine(callStatsModel.audioBandwidth)
                statLine(callStatsModel.audioLossRate)
                statLine(callStatsModel.audioJitterBufferSize)

                if callStatsModel.isVideoEnabled {
                    Divider().background(.white.opacity(0.3))
                    statLine(callStatsModel.videoCodec)
                    statLine(callStatsModel.videoBandwidth)
                    statLine(callStatsModel.videoLossRate)
                    statLine(callStatsModel.videoResolution)
                    statLine(callStatsModel.videoFps)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .animation(.easeInOut(duration: 0.3), value: vpnManager.latestStats?.activePath)
    }

    @ViewBuilder
    private func statLine(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(.white.opacity(0.8))
    }

    @ViewBuilder
    private func pathRow(
        label: String,
        pathStats: PathStats?,
        isActive: Bool,
        activeColor: Color,
        kbpsIn: Double?,
        kbpsOut: Double?
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isActive ? "circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundStyle(isActive ? activeColor : activeColor.opacity(0.5))

            Text(label)
                .font(.system(size: 20, weight: isActive ? .bold : .regular, design: .monospaced))
                .foregroundStyle(isActive ? .white : .white.opacity(0.6))
                .frame(width: 52, alignment: .leading)

            if let ps = pathStats, ps.isAvailable {
                Text(String(format: "%.0fms", ps.srttMs))
                    .font(.system(size: 20, design: .monospaced))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.6))
                    .frame(width: 64, alignment: .trailing)

                Text(String(format: "%.1f%%", ps.packetLossPercent))
                    .font(.system(size: 20, design: .monospaced))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.6))
                    .frame(width: 64, alignment: .trailing)

                if let downKbps = kbpsIn, let upKbps = kbpsOut {
                    Text(formatThroughput(downKbps, up: upKbps))
                        .font(.system(size: 20, design: .monospaced))
                        .foregroundStyle(isActive ? .white : .white.opacity(0.6))
                }
            } else {
                Text("--")
                    .font(.system(size: 20, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private var mosColor: Color {
        switch floor(qualityValue) {
        case 4, 5: return .green
        case 3: return .yellow
        case 2: return .orange
        default: return .red
        }
    }

    private func formatThroughput(_ downKbps: Double, up upKbps: Double) -> String {
        return String(format: "↑%.0f ↓%.0f kbps", downKbps, upKbps)
    }
}
