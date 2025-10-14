import SwiftUI
import Combine

public struct BandwidthCompactView: View {
    @ObservedObject public var monitor: BandwidthMonitor
    @AppStorage("useMbps") private var useMbps: Bool = true

    public init(monitor: BandwidthMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        HStack(spacing: 8) {
            if let s = monitor.latest {
                Text("↑ " + formatThroughput(bytesPerSecond: s.totalOutBps, units: useMbps ? .mbps : .mBps))
                Text("↓ " + formatThroughput(bytesPerSecond: s.totalInBps, units: useMbps ? .mbps : .mBps))
            } else {
                Text("Measuring…")
            }
        }
        .monospacedDigit()
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
    }
}

