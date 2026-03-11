import WidgetKit
import SwiftUI

// MARK: - Shared data keys
private let appGroup = "group.com.bandwidth-monitor.shared"

// MARK: - Entry
struct BandwidthEntry: TimelineEntry {
    let date: Date
    let down24h: UInt64
    let up24h: UInt64
    let cycleDown: UInt64
    let cycleUp: UInt64
    let peakDown: Double
    let peakUp: Double
    let capEnabled: Bool
    let capGB: Double
    let lastUpdated: Date?
}

// MARK: - Helpers
private func formatTotal(_ bytes: UInt64) -> String {
    let factor: Double = 1_000_000_000
    if bytes == 0 { return "0 GB" }
    let gb = Double(bytes) / factor
    if gb >= 1 { return String(format: "%.2f GB", gb) }
    let mb = Double(bytes) / 1_000_000
    if mb >= 1 { return String(format: "%.0f MB", mb) }
    return String(format: "%.0f KB", Double(bytes) / 1_000)
}

private func formatRate(_ bytesPerSec: Double) -> String {
    if bytesPerSec <= 0 { return "0 Mbps" }
    let mbps = bytesPerSec * 8 / 1_000_000
    if mbps >= 1000 { return String(format: "%.2f Gbps", mbps / 1000) }
    if mbps >= 1 { return String(format: "%.1f Mbps", mbps) }
    let kbps = bytesPerSec * 8 / 1_000
    return String(format: "%.0f kbps", kbps)
}

// MARK: - TimelineProvider
struct BandwidthProvider: TimelineProvider {
    func placeholder(in context: Context) -> BandwidthEntry {
        BandwidthEntry(
            date: Date(),
            down24h: 4_200_000_000,
            up24h: 512_000_000,
            cycleDown: 18_700_000_000,
            cycleUp: 2_100_000_000,
            peakDown: 30_000_000,
            peakUp: 5_000_000,
            capEnabled: true,
            capGB: 30,
            lastUpdated: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BandwidthEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BandwidthEntry>) -> Void) {
        let e = entry()
        // Refresh every 15 minutes; the main app also triggers reloads on its own schedule
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: e.date) ?? e.date
        completion(Timeline(entries: [e], policy: .after(next)))
    }

    private func entry() -> BandwidthEntry {
        let d = UserDefaults(suiteName: appGroup)
        return BandwidthEntry(
            date: Date(),
            down24h: (d?.object(forKey: "widget_24h_down") as? UInt64) ?? 0,
            up24h: (d?.object(forKey: "widget_24h_up") as? UInt64) ?? 0,
            cycleDown: (d?.object(forKey: "widget_cycle_down") as? UInt64) ?? 0,
            cycleUp: (d?.object(forKey: "widget_cycle_up") as? UInt64) ?? 0,
            peakDown: d?.double(forKey: "widget_peak_down") ?? 0,
            peakUp: d?.double(forKey: "widget_peak_up") ?? 0,
            capEnabled: d?.bool(forKey: "widget_cap_enabled") ?? false,
            capGB: d?.double(forKey: "widget_cap_gb") ?? 0,
            lastUpdated: d?.object(forKey: "widget_last_updated") as? Date
        )
    }
}

// MARK: - Widget View
struct BandwidthWidgetEntryView: View {
    var entry: BandwidthEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        default:
            mediumView
        }
    }

    // MARK: Small (2×2)
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Bandwidth", systemImage: "network")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 2) {
                Text("Last 24 h")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text("↓").foregroundStyle(.green)
                    Text(formatTotal(entry.down24h))
                        .font(.caption.weight(.semibold))
                }
                HStack(spacing: 4) {
                    Text("↑").foregroundStyle(.red)
                    Text(formatTotal(entry.up24h))
                        .font(.caption.weight(.semibold))
                }
            }

            Spacer(minLength: 0)

            if entry.capEnabled && entry.capGB > 0 {
                let capBytes = UInt64(entry.capGB * 1_000_000_000)
                let used = entry.cycleDown + entry.cycleUp
                let pct = min(1.0, Double(used) / Double(capBytes))
                VStack(alignment: .leading, spacing: 2) {
                    ProgressView(value: pct)
                        .tint(pct > 0.9 ? .red : pct > 0.75 ? .orange : .green)
                    Text("\(Int(pct * 100))% of \(Int(entry.capGB)) GB")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                updatedText
            }
        }
        .padding(14)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: Medium (4×2)
    private var mediumView: some View {
        HStack(spacing: 0) {
            // Left column: 24h totals
            VStack(alignment: .leading, spacing: 6) {
                Label("Last 24 Hours", systemImage: "clock")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 3) {
                    statRow(arrow: "↓", color: .green, value: formatTotal(entry.down24h))
                    statRow(arrow: "↑", color: .red,   value: formatTotal(entry.up24h))
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Peak speeds")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    statRow(arrow: "↓", color: .green, value: formatRate(entry.peakDown), size: .caption2)
                    statRow(arrow: "↑", color: .red,   value: formatRate(entry.peakUp),   size: .caption2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().padding(.horizontal, 8)

            // Right column: cycle + cap
            VStack(alignment: .leading, spacing: 6) {
                Label("This Cycle", systemImage: "calendar")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 3) {
                    statRow(arrow: "↓", color: .green, value: formatTotal(entry.cycleDown))
                    statRow(arrow: "↑", color: .red,   value: formatTotal(entry.cycleUp))
                }

                Spacer(minLength: 0)

                if entry.capEnabled && entry.capGB > 0 {
                    let capBytes = UInt64(entry.capGB * 1_000_000_000)
                    let used = entry.cycleDown + entry.cycleUp
                    let pct = min(1.0, Double(used) / Double(capBytes))
                    VStack(alignment: .leading, spacing: 3) {
                        ProgressView(value: pct)
                            .tint(pct > 0.9 ? .red : pct > 0.75 ? .orange : .green)
                        Text("\(Int(pct * 100))% of \(Int(entry.capGB)) GB used")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    updatedText
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func statRow(arrow: String, color: Color, value: String, size: Font = .caption) -> some View {
        HStack(spacing: 4) {
            Text(arrow)
                .font(size.weight(.semibold))
                .foregroundStyle(color)
            Text(value)
                .font(size.weight(.medium))
        }
    }

    private var updatedText: some View {
        Group {
            if let updated = entry.lastUpdated {
                Text("Updated \(updated, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Widget
struct BandwidthWidget: Widget {
    let kind: String = "BandwidthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BandwidthProvider()) { entry in
            BandwidthWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bandwidth Monitor")
        .description("Shows your last 24 h usage, current billing cycle totals, and data cap progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
