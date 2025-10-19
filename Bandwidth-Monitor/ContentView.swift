// MenuBarBandwidthMonitor.swift


import SwiftUI
import Combine
import AppKit

struct AboutBandwidthManagerView: View {
    var onClose: (() -> Void)?
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 10) {
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Version \(version) (\(build))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text("A small, lightweight network monitor that tracks upload and download values.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .padding(.horizontal, 10)
                Text("Bandwidth Monitor shows real-time download / upload speeds in your menu bar.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .padding(.horizontal, 10)
                Text("Lightweight, clear, and private — no accounts, no tracking.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .padding(.horizontal, 10)
                Button("Close") {
                    onClose?()
                }
                .keyboardShortcut(.defaultAction)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 340, height: 190)
        .padding(.top, 0)
    }
}

@main
struct MenuBarBandwidthMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var monitor: BandwidthMonitor!
    var timerCancellable: AnyCancellable?
    var detailsPopover: NSPopover?
    var aboutWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Make the status bar button have a solid white background
        if let button = statusItem.button {
            button.wantsLayer = true
            button.layer?.backgroundColor = NSColor.white.cgColor
            button.layer?.cornerRadius = 4
        }
        statusItem.button?.title = "…"
        statusItem.button?.toolTip = "Bandwidth monitor"

        // Simple menu with Quit
        let menu = NSMenu()
        let openStatsItem = NSMenuItem(title: "Open download and upload Statistics", action: #selector(openDetails), keyEquivalent: "")
        openStatsItem.target = self
        openStatsItem.image = nil
        openStatsItem.onStateImage = nil
        openStatsItem.offStateImage = nil
        openStatsItem.mixedStateImage = nil
        menu.insertItem(openStatsItem, at: 0)
        let aboutItem = NSMenuItem(title: "About Bandwidth Monitor", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        aboutItem.image = nil
        aboutItem.onStateImage = nil
        aboutItem.offStateImage = nil
        aboutItem.mixedStateImage = nil
        menu.insertItem(aboutItem, at: 1)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit Bandwidth Monitor", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu

        monitor = BandwidthMonitor()

        // Update UI every 1 second
        timerCancellable = monitor.$rates
            .receive(on: RunLoop.main)
            .sink { [weak self] (rates: BandwidthRates) in
                guard let self = self else { return }
                let title = "↓ \(rates.download)/s | ↑ \(rates.upload)/s"
                // Build attributed string with green download and red upload
                let fullString = NSMutableAttributedString(string: title)
                let fullRange = NSRange(location: 0, length: fullString.length)

                // Use a darker green for download text
                let darkGreen = NSColor(calibratedRed: 0.0, green: 0.45, blue: 0.0, alpha: 1.0)

                // Helper to bold numeric parts (digits, dots, commas) in a given range
                func boldNumbers(in attributed: NSMutableAttributedString, title: String, range: NSRange) {
                    let pattern = "[0-9.,]+"
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        let nsTitle = title as NSString
                        let subString = nsTitle.substring(with: range)
                        let subRange = NSRange(location: 0, length: (subString as NSString).length)
                        let matches = regex.matches(in: subString, range: subRange)
                        let boldFont = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
                        for match in matches {
                            let adjusted = NSRange(location: range.location + match.range.location, length: match.range.length)
                            attributed.addAttribute(.font, value: boldFont, range: adjusted)
                        }
                    }
                }

                // Default attributes
                fullString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

                // Find range of download part: "↓ \(rates.download)/s"
                let downloadString = "↓ \(rates.download)/s"
                if let downloadRange = title.range(of: downloadString) {
                    let nsDownloadRange = NSRange(downloadRange, in: title)
                    fullString.addAttribute(.foregroundColor, value: darkGreen, range: nsDownloadRange)
                    // Bold the numeric portion of the download string
                    boldNumbers(in: fullString, title: title, range: nsDownloadRange)
                }

                // Find range of upload part: "↑ \(rates.upload)/s"
                let uploadString = "↑ \(rates.upload)/s"
                if let uploadRange = title.range(of: uploadString) {
                    let nsUploadRange = NSRange(uploadRange, in: title)
                    fullString.addAttribute(.foregroundColor, value: NSColor.systemRed, range: nsUploadRange)
                    // Bold the numeric portion of the upload string
                    boldNumbers(in: fullString, title: title, range: nsUploadRange)
                }

                // Set the attributed string to statusItem.button
                self.statusItem.button?.attributedTitle = fullString
                // self.statusItem.button?.title = title // old line commented out

                self.statusItem.button?.toolTip = "Download: \(rates.download)/s\nUpload: \(rates.upload)/s"
            }

        monitor.start()
    }

    @objc func showAbout(_ sender: Any?) {
        if let win = aboutWindowController, win.window?.isVisible == true {
            win.window?.makeKeyAndOrderFront(nil)
            return
        }
        let contentView = AboutBandwidthManagerView { [weak self] in
            self?.aboutWindowController?.close()
            self?.aboutWindowController = nil
        }
        let hosting = NSHostingController(rootView: contentView)
        // Use the correct label: contentViewController (not contentViewViewController)
        let window = NSWindow(contentViewController: hosting)
        window.title = "About Bandwidth Monitor"
        window.setContentSize(NSSize(width: 340, height: 190))
        window.styleMask.insert(NSWindow.StyleMask.titled)
        window.styleMask.insert(NSWindow.StyleMask.closable)
        window.isReleasedWhenClosed = false
        let controller = NSWindowController(window: window)
        self.aboutWindowController = controller
        controller.showWindow(self)
        window.center()
    }

    @objc func openDetails(_ sender: Any?) {
        if let popover = detailsPopover, popover.isShown {
            popover.performClose(nil)
            detailsPopover = nil
            return
        }
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 210)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: BandwidthTotalsView(monitor: monitor))
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            detailsPopover = popover
        }
    }

    @objc func quitApp(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Bandwidth Monitor Implementation
import Foundation
import Network
import Combine

struct BandwidthRates {
    var download: String
    var upload: String
    var timestamp: Date // Add this field
}

final class BandwidthMonitor: ObservableObject {
    // Codable struct to represent history sample for persistence
    private struct HistorySample: Codable {
        let timestamp: Date
        let rx: UInt64
        let tx: UInt64
    }
    
    @Published var rates = BandwidthRates(download: "0 Mbps", upload: "0 Mbps", timestamp: Date())
    private var timer: Timer?
    private var prevRx: UInt64 = 0
    private var prevTx: UInt64 = 0
    private var isFirstSample = true
    // Store history as array of HistorySample for codable persistence
    private var history: [HistorySample] = []
    
    private var totalDownloadAllTime: UInt64 = 0
    private var totalUploadAllTime: UInt64 = 0
    
    // Expose as a property
    var totalsAllTime: (download: UInt64, upload: UInt64) {
        (totalDownloadAllTime, totalUploadAllTime)
    }
    
    // Define a struct to hold all persistent data, replacing the old array root
    private struct PersistedData: Codable {
        let history: [HistorySample]
        let totalDownloadAllTime: UInt64
        let totalUploadAllTime: UInt64
    }
    
    // File URL to save/load history JSON data
    private var historyURL: URL {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDir = dir.appendingPathComponent("MenuBarBandwidthMonitor", isDirectory: true)
        try? fm.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("history.json")
    }
    
    // Computed property to get total download/upload bytes in last 24 hours
    var totalsLast24Hours: (download: UInt64, upload: UInt64) {
        let cutoff = Date().addingTimeInterval(-86400)
        var totalRx: UInt64 = 0
        var totalTx: UInt64 = 0

        // Helper to safely compute delta between two monotonically increasing counters that may reset/wrap
        func safeDelta(newer: UInt64, older: UInt64) -> UInt64 {
            if newer >= older {
                return newer &- older
            } else {
                // Counter reset or wrap; best effort: count the newer value as the delta since reset
                return newer
            }
        }

        // Sum differences between consecutive samples within the last 24 hours
        for i in 1..<history.count {
            let t0 = history[i-1]
            let t1 = history[i]
            if t1.timestamp >= cutoff {
                totalRx &+= safeDelta(newer: t1.rx, older: t0.rx)
                totalTx &+= safeDelta(newer: t1.tx, older: t0.tx)
            }
        }
        return (totalRx, totalTx)
    }
    
    init() {
        loadHistory() // Load history from disk on startup
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        saveHistory() // Save the history when stopping monitoring
    }
    
    private func poll() {
        let (rx, tx) = getNetworkBytes()
        guard rx >= 0 && tx >= 0 else { return }
        if isFirstSample {
            prevRx = rx
            prevTx = tx
            isFirstSample = false
            return
        }
        // Handle counter wraparound (interface reset or overflow)
        let deltaRx: UInt64 = rx >= prevRx ? rx - prevRx : rx
        let deltaTx: UInt64 = tx >= prevTx ? tx - prevTx : tx
        
        prevRx = rx
        prevTx = tx

        // Increment totals all time
        totalDownloadAllTime &+= deltaRx
        totalUploadAllTime &+= deltaTx
        
        // Append new sample to history with current timestamp and byte counters
        history.append(HistorySample(timestamp: Date(), rx: rx, tx: tx))
        // Remove old samples beyond 24 hours to keep history size manageable
        let dayAgo = Date().addingTimeInterval(-86400)
        history.removeAll { $0.timestamp < dayAgo }
        saveHistory() // Persist updated history to disk

        DispatchQueue.main.async {
            self.rates = BandwidthRates(
                download: Self.format(bytes: deltaRx),
                upload: Self.format(bytes: deltaTx),
                timestamp: Date()
            )
        }
    }
    
    private func getNetworkBytes() -> (UInt64, UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        var rx: UInt64 = 0
        var tx: UInt64 = 0
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let flags = Int32(ptr!.pointee.ifa_flags)
                _ = ptr!.pointee.ifa_addr.pointee
                // Only count interfaces that are UP and not LOOPBACK
                if (flags & (IFF_UP|IFF_RUNNING) == (IFF_UP|IFF_RUNNING)) && (flags & IFF_LOOPBACK == 0) {
                    if let data = unsafeBitCast(ptr!.pointee.ifa_data, to: UnsafeMutablePointer<if_data>?.self) {
                        rx += UInt64(data.pointee.ifi_ibytes)
                        tx += UInt64(data.pointee.ifi_obytes)
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return (rx, tx)
    }
    
    static func format(bytes: UInt64) -> String {
        let bitsPerSecond = Double(bytes) * 8.0
        // Use decimal (SI) units: 1 kbps = 1,000 bps; 1 Mbps = 1,000,000 bps; 1 Gbps = 1,000,000,000 bps
        let gbps = bitsPerSecond / 1_000_000_000.0
        if gbps >= 1.0 {
            return String(format: "%.2f Gbps", gbps)
        }
        let mbps = bitsPerSecond / 1_000_000.0
        if mbps >= 1.0 {
            return String(format: "%.2f Mbps", mbps)
        }
        let kbps = bitsPerSecond / 1_000.0
        return String(format: "%.0f kbps", kbps)
    }
    
    // Formats a raw byte total into human-readable units (kB, MB, GB, TB) using decimal SI units.
    static func formatTotal(bytes: UInt64) -> String {
        let b = Double(bytes)
        let tb = b / 1_000_000_000_000.0
        if tb >= 1.0 { return String(format: "%.2f TB", tb) }
        let gb = b / 1_000_000_000.0
        if gb >= 1.0 { return String(format: "%.2f GB", gb) }
        let mb = b / 1_000_000.0
        if mb >= 1.0 { return String(format: "%.2f MB", mb) }
        let kb = b / 1_000.0
        if kb >= 1.0 { return String(format: "%.0f kB", kb) }
        return String(format: "%.0f B", b)
    }
    
    // Save history array as JSON to disk atomically
    private func saveHistory() {
        do {
            let dataToSave = PersistedData(history: history, totalDownloadAllTime: totalDownloadAllTime, totalUploadAllTime: totalUploadAllTime)
            let data = try JSONEncoder().encode(dataToSave)
            try data.write(to: historyURL, options: .atomic)
        } catch {
            // ignore errors
        }
    }
    
    // Load history array from JSON file on disk, filtering out old samples
    private func loadHistory() {
        do {
            let data = try Data(contentsOf: historyURL)
            if let object = try? JSONDecoder().decode(PersistedData.self, from: data) {
                let dayAgo = Date().addingTimeInterval(-86400)
                history = object.history.filter { $0.timestamp >= dayAgo }
                totalDownloadAllTime = object.totalDownloadAllTime
                totalUploadAllTime = object.totalUploadAllTime
            } else if let old = try? JSONDecoder().decode([HistorySample].self, from: data) {
                let dayAgo = Date().addingTimeInterval(-86400)
                history = old.filter { $0.timestamp >= dayAgo }
                totalDownloadAllTime = 0
                totalUploadAllTime = 0
            }
        } catch {
            history = []
            totalDownloadAllTime = 0
            totalUploadAllTime = 0
        }
    }
    
    func resetTotals() {
        DispatchQueue.main.async {
            self.history = []
            self.totalDownloadAllTime = 0
            self.totalUploadAllTime = 0
            self.prevRx = 0
            self.prevTx = 0
            self.isFirstSample = true
            self.saveHistory()
            self.rates = BandwidthRates(download: "0 Mbps", upload: "0 Mbps", timestamp: Date())
        }
    }
}

struct BandwidthTotalsView: View {
    @ObservedObject var monitor: BandwidthMonitor
    @State private var showResetAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Total Data Downloaded Since Last Reset")
                .font(.title2).bold()
            HStack {
                VStack(alignment: .leading) {
                    Text("Download")
                        .font(.headline)
                    Text(BandwidthMonitor.formatTotal(bytes: monitor.totalsAllTime.download))
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.green)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Upload")
                        .font(.headline)
                    Text(BandwidthMonitor.formatTotal(bytes: monitor.totalsAllTime.upload))
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
            .padding(.top, 8)
            
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Text("Reset Totals")
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 16)
            .buttonStyle(.borderedProminent)
            .alert("Reset All Bandwidth Totals?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    monitor.resetTotals()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all statistics for the all-time totals. This cannot be undone.")
            }
            
            Spacer()
        }
        .frame(width: 320, height: 260)
        .padding(18)
    }
}

