import SwiftUI

struct MenuBarRootView: View {
    @ObservedObject var monitor: BandwidthMonitor
    @AppStorage("useMbps") private var useMbps: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BandwidthCompactView(monitor: monitor)
            Toggle(isOn: $useMbps) {
                Text("Show Mbps (vs MB/s)")
            }
            .toggleStyle(.switch)
            Divider()
            Button("Quit Bandwidth Monitor") {
                NSApp.terminate(nil)
            }
        }
        .padding(8)
    }
}
