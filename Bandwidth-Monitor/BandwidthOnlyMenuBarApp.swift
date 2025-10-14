import SwiftUI

@main
struct BandwidthOnlyMenuBarApp: App {
    @StateObject private var monitor = BandwidthMonitor()
    @AppStorage("useMbps") private var useMbps: Bool = true

    var body: some Scene {
        MenuBarExtra {
            // Menu content
            MenuBarRootView(monitor: monitor)
        } label: {
            // Status bar label showing live speeds
            HStack(spacing: 6) {
                Image(systemName: "speedometer")
                if let s = monitor.latest {
                    Text("↑ " + formatThroughput(bytesPerSecond: s.totalOutBps, units: useMbps ? .mbps : .mBps))
                    Text("↓ " + formatThroughput(bytesPerSecond: s.totalInBps, units: useMbps ? .mbps : .mBps))
                } else {
                    Text("— —")
                }
            }
            .monospacedDigit()
            .task { monitor.start() }
        }
    }
}
