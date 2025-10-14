import SwiftUI
import Combine
import Foundation

// MARK: - Units + Formatting (inline)

enum ThroughputUnits: String {
    case mbps // megabits per second (decimal)
    case mBps // megabytes per second (decimal)
}

struct ThroughputFormatter {
    static let shared = ThroughputFormatter()
    private let formatter: NumberFormatter

    private init() {
        formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
    }

    func string(from bytesPerSecond: Double, units: ThroughputUnits) -> String {
        switch units {
        case .mbps:
            let value = (bytesPerSecond * 8.0) / 1_000_000.0
            let formatted = formatter.string(from: NSNumber(value: value)) ?? "0.0"
            return "\(formatted) Mbps"
        case .mBps:
            let value = bytesPerSecond / 1_000_000.0
            let formatted = formatter.string(from: NSNumber(value: value)) ?? "0.0"
            return "\(formatted) MB/s"
        }
    }

    func numberString(from bytesPerSecond: Double, units: ThroughputUnits) -> String {
        switch units {
        case .mbps:
            let value = (bytesPerSecond * 8.0) / 1_000_000.0
            return formatter.string(from: NSNumber(value: value)) ?? "0.0"
        case .mBps:
            let value = bytesPerSecond / 1_000_000.0
            return formatter.string(from: NSNumber(value: value)) ?? "0.0"
        }
    }
}

@propertyWrapper
struct ThroughputUnitsStorage {
    @AppStorage("ThroughputUnitsKey")
    private var rawValue: String = ThroughputUnits.mbps.rawValue

    var wrappedValue: ThroughputUnits {
        get { ThroughputUnits(rawValue: rawValue) ?? .mbps }
        set { rawValue = newValue.rawValue }
    }

    init() {}
}

// MARK: - Network Stats Reading (inline)

struct InterfaceStats {
    let name: String
    let bytesIn: UInt64
    let bytesOut: UInt64
}

enum NetworkStatsReader {
    static func readInterfaces() -> [InterfaceStats] {
        var result: [InterfaceStats] = []
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return result }
        defer { freeifaddrs(ifaddrPtr) }

        var ptr = first
        while true {
            let ifa = ptr.pointee
            let name = String(cString: ifa.ifa_name)
            if let dataPtr = ifa.ifa_data?.assumingMemoryBound(to: if_data.self) {
                let data = dataPtr.pointee
                if (ifa.ifa_flags & UInt32(IFF_LOOPBACK)) == 0 {
                    result.append(InterfaceStats(name: name,
                                                 bytesIn: UInt64(data.ifi_ibytes),
                                                 bytesOut: UInt64(data.ifi_obytes)))
                }
            }
            guard let next = ifa.ifa_next else { break }
            ptr = next
        }
        return result
    }
}

// MARK: - Monitor (inline)

@MainActor
final class BandwidthMonitor: ObservableObject {
    struct Speeds {
        let timestamp: Date
        let totalInBps: Double
        let totalOutBps: Double
        let perInterface: [String: (inBps: Double, outBps: Double)]
    }

    @Published var latest: Speeds?

    private var lastSample: [String: (inBytes: UInt64, outBytes: UInt64)] = [:]
    private var task: Task<Void, Never>?

    func start() {
        stop()
        task = Task.detached { [weak self] in
            var lastTime = Date()
            while !Task.isCancelled {
                let now = Date()
                let dt = now.timeIntervalSince(lastTime)
                lastTime = now

                let interfaces = NetworkStatsReader.readInterfaces()

                await MainActor.run {
                    var per: [String: (Double, Double)] = [:]
                    var totalIn: Double = 0
                    var totalOut: Double = 0

                    for s in interfaces {
                        let prev = self?.lastSample[s.name]
                        let dIn = prev != nil ? Double(s.bytesIn &- prev!.inBytes) : 0
                        let dOut = prev != nil ? Double(s.bytesOut &- prev!.outBytes) : 0
                        let inBps = dt > 0 ? dIn / dt : 0
                        let outBps = dt > 0 ? dOut / dt : 0
                        per[s.name] = (inBps, outBps)
                        totalIn += inBps
                        totalOut += outBps
                    }

                    self?.lastSample = Dictionary(uniqueKeysWithValues: interfaces.map { ($0.name, ($0.bytesIn, $0.bytesOut)) })
                    self?.latest = Speeds(timestamp: now, totalInBps: totalIn, totalOutBps: totalOut, perInterface: per)
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}

// MARK: - Compact Menu Label View (inline)

struct CompactStatusLabel: View {
    @ObservedObject var monitor: BandwidthMonitor
    @ThroughputUnitsStorage private var units: ThroughputUnits

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if let s = monitor.latest {
                    HStack(spacing: 6) {
                        Text("↑ " + ThroughputFormatter.shared.numberString(from: s.totalOutBps, units: units))
                            .foregroundStyle(.green)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text("↓ " + ThroughputFormatter.shared.numberString(from: s.totalInBps, units: units))
                            .foregroundStyle(.red)
                    }
                    .monospacedDigit()
                } else {
                    Text("— —")
                        .monospacedDigit()
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
        }
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Menu Content (optional tiny dropdown)

struct MenuContent: View {
    var body: some View {
        Button("Quit Bandwidth Monitor") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: [.command])
        .padding(6)
    }
}

// MARK: - App (menu bar only)

@main
struct BandwidthOnlyMenuBarApp: App {
    @StateObject private var monitor = BandwidthMonitor()

    var body: some Scene {
        MenuBarExtra {
            // Minimal dropdown: only Quit with a keyboard shortcut
            MenuContent()
        } label: {
            CompactStatusLabel(monitor: monitor)
                .task { monitor.start() }
        }
    }
}
