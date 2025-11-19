// MenuBarBandwidthMonitor.swift


import SwiftUI
import Combine
import AppKit
import StoreKit
import ServiceManagement
import Charts // Optional: for macOS 13+
import CoreWLAN

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

// MARK: - Tip Jar
final class TipJarManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var purchaseInProgress = false
    @Published var lastError: String?
    @Published var lastPurchaseMessage: String?

    let productIDs: [String] = [
        "tip.coffee.199"
    ]
    
    @Published var coffeeProduct: Product?
    
    private var updatesTask: Task<Void, Never>? = nil
    
    deinit {
        updatesTask?.cancel()
    }
    
    func startListeningForTransactions() {
        // Finish any existing verified entitlements (defensive)
        updatesTask = Task.detached(priority: .background) {
            // Finish any existing verified entitlements (defensive)
            for await result in StoreKit.Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                case .unverified:
                    break
                }
            }

            // Listen for new transaction updates
            for await result in StoreKit.Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                case .unverified:
                    break
                }
            }
        }
    }

    func load() async {
        await MainActor.run { self.isLoading = true; self.lastError = nil }
        do {
            let storeProducts = try await Product.products(for: productIDs)
            await MainActor.run {
                self.products = storeProducts
                self.coffeeProduct = storeProducts.first
            }
        } catch {
            await MainActor.run { self.lastError = error.localizedDescription }
        }
        await MainActor.run { self.isLoading = false }
    }

    func tip(_ product: Product) async {
        await MainActor.run { self.purchaseInProgress = true; self.lastError = nil; self.lastPurchaseMessage = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                _ = try verification.payloadValue
                await MainActor.run { self.lastPurchaseMessage = "Thank you!" }
            case .pending:
                await MainActor.run { self.lastPurchaseMessage = "Purchase pending approval." }
            case .userCancelled:
                await MainActor.run { self.lastPurchaseMessage = nil }
            @unknown default:
                break
            }
        } catch {
            await MainActor.run { self.lastError = error.localizedDescription }
        }
        await MainActor.run { self.purchaseInProgress = false }
    }
}

struct TipJarView: View {
    @StateObject private var manager: TipJarManager
    var onClose: (() -> Void)?

    init(manager: TipJarManager = TipJarManager(), onClose: (() -> Void)? = nil) {
        _manager = StateObject(wrappedValue: manager)
        self.onClose = onClose
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Tip Jar")
                    .font(.title2).bold()
                Text("If you find Bandwidth Monitor useful, consider buying me a coffee. Thank you!")
                    .foregroundStyle(.secondary)

                if manager.isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let err = manager.lastError {
                    VStack(spacing: 8) {
                        Text("Couldn’t load products.")
                        Text(err).font(.footnote).foregroundStyle(.secondary)
                        Button("Retry") { Task { await manager.load() } }
                    }
                    .frame(maxWidth: .infinity)
                } else if manager.products.isEmpty {
                    Text("No tip options are currently available.")
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Buy me a coffee")
                            .font(.headline)
                        Text("Support development with a small tip.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Spacer()
                            Button(manager.purchaseInProgress ? "…" : (manager.coffeeProduct.map { "\($0.displayName) – \($0.displayPrice)" } ?? "Tip")) {
                                if let product = manager.coffeeProduct {
                                    Task { await manager.tip(product) }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(manager.purchaseInProgress || manager.coffeeProduct == nil)
                            
                            if let msg = manager.lastPurchaseMessage {
                                Text(msg)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Close") { onClose?() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
        .padding(18)
        .task { await manager.load() }
    }
}

// MARK: - Preferences & Settings
final class Preferences: ObservableObject {
    static let shared = Preferences()
    @Published var launchAtLogin: Bool {
        didSet { Self.setLaunchAtLogin(launchAtLogin) }
    }
    @Published var runAsHiddenService: Bool {
        didSet {
            UserDefaults.standard.set(runAsHiddenService, forKey: "runAsHiddenService")
        }
    }
    
    @Published var samplingInterval: Double {
        didSet {
            UserDefaults.standard.set(samplingInterval, forKey: "samplingInterval")
        }
    }
    @Published var showBitsPerSecond: Bool {
        didSet {
            UserDefaults.standard.set(showBitsPerSecond, forKey: "showBitsPerSecond")
        }
    }
    @Published var useSIUnits: Bool {
        didSet {
            UserDefaults.standard.set(useSIUnits, forKey: "useSIUnits")
        }
    }
    @Published var selectedInterfaces: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(selectedInterfaces), forKey: "selectedInterfaces")
        }
    }
    @Published var dataCapEnabled: Bool {
        didSet { UserDefaults.standard.set(dataCapEnabled, forKey: "dataCapEnabled") }
    }
    @Published var dataCapGB: Double {
        didSet { UserDefaults.standard.set(dataCapGB, forKey: "dataCapGB") }
    }
    @Published var billingDay: Int {
        didSet { UserDefaults.standard.set(billingDay, forKey: "billingDay") }
    }

    private init() {
        // Initialize from system/user defaults
        self.launchAtLogin = Self.currentLaunchAtLogin()
        self.runAsHiddenService = UserDefaults.standard.bool(forKey: "runAsHiddenService")
        
        self.samplingInterval = UserDefaults.standard.object(forKey: "samplingInterval") as? Double ?? 1.0
        self.showBitsPerSecond = UserDefaults.standard.object(forKey: "showBitsPerSecond") as? Bool ?? true
        self.useSIUnits = UserDefaults.standard.object(forKey: "useSIUnits") as? Bool ?? true
        if let arr = UserDefaults.standard.array(forKey: "selectedInterfaces") as? [String] {
            self.selectedInterfaces = Set(arr)
        } else {
            self.selectedInterfaces = []
        }
        self.dataCapEnabled = UserDefaults.standard.object(forKey: "dataCapEnabled") as? Bool ?? false
        self.dataCapGB = UserDefaults.standard.object(forKey: "dataCapGB") as? Double ?? 500.0
        self.billingDay = UserDefaults.standard.object(forKey: "billingDay") as? Int ?? 1
    }

    // MARK: Launch at Login helpers
    private static func currentLaunchAtLogin() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // Older macOS: we don't manage here; default to stored preference if any
            return UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
    }

    private static func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
            } catch {
                // Revert on failure
                UserDefaults.standard.set(!enabled, forKey: "launchAtLogin")
            }
        } else {
            // Persist intent but cannot programmatically change on old systems without deprecated APIs
            UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        }
    }
}

struct SettingsView: View {
    @ObservedObject private var prefs = Preferences.shared
    var onClose: (() -> Void)?
    @State private var showRelaunchHint = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings").font(.title2).bold()

            Toggle(isOn: Binding(
                get: { prefs.launchAtLogin },
                set: { newValue in
                    prefs.launchAtLogin = newValue
                }
            )) {
                VStack(alignment: .leading) {
                    Text("Launch at login")
                    Text("Automatically start Bandwidth Monitor when you sign in.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: Binding(
                get: { prefs.runAsHiddenService },
                set: { newValue in
                    prefs.runAsHiddenService = newValue
                    showRelaunchHint = true
                }
            )) {
                VStack(alignment: .leading) {
                    Text("Run as hidden service")
                    Text("Hide the Dock icon and run in the background. Requires relaunch.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Sampling").font(.headline)
                Text("Choose a preset or fine-tune below.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Picker("Presets", selection: $prefs.samplingInterval) {
                    Text("0.25 s").tag(0.25)
                    Text("0.5 s").tag(0.5)
                    Text("1 s").tag(1.0)
                    Text("2 s").tag(2.0)
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Monitoring").font(.headline)
                HStack {
                    Text("Sampling interval")
                    Spacer()
                    Stepper(value: $prefs.samplingInterval, in: 0.25...5.0, step: 0.25) {
                        Text(String(format: "%.2f s", prefs.samplingInterval))
                    }
                    .frame(width: 160)
                }
                Toggle(isOn: $prefs.showBitsPerSecond) {
                    Text("Show bits per second (instead of bytes)")
                }
                Toggle(isOn: $prefs.useSIUnits) {
                    Text("Use SI units (1000) instead of IEC (1024)")
                }
            }
            .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Interfaces").font(.headline)
                Text("Select interfaces to include. Leave empty to include all.").font(.footnote).foregroundStyle(.secondary)
                InterfacePickerView(selected: $prefs.selectedInterfaces)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Data Cap").font(.headline)
                Toggle(isOn: $prefs.dataCapEnabled) {
                    Text("Enable monthly data cap tracking")
                }
                HStack {
                    Text("Cap size")
                    Spacer()
                    Stepper(value: $prefs.dataCapGB, in: 1...5000, step: 1) {
                        Text(String(format: "%.0f GB", prefs.dataCapGB))
                    }
                    .frame(width: 160)
                }
                HStack {
                    Text("Billing day")
                    Spacer()
                    Picker("Billing day", selection: $prefs.billingDay) {
                        ForEach(1...28, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .frame(width: 120)
                }
            }

            if showRelaunchHint {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                    Text("Please quit and reopen the app to apply this change.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            HStack {
                if showRelaunchHint {
                    Button("Relaunch Now") {
                        relaunchApp()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer()
            HStack {
                Spacer()
                Button("Close") { onClose?() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(18)
    }
    
    private func relaunchApp() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [Bundle.main.bundlePath]
        do {
            try task.run()
        } catch {
            // ignore
        }
        NSApplication.shared.terminate(nil)
    }
}

struct InterfacePickerView: View {
    @Binding var selected: Set<String>
    @State private var interfaces: [String] = []
    
    // Cache the Wi‑Fi BSD interface name if available (e.g., "en0")
    private static let wifiBSDName: String? = CWWiFiClient.shared().interface()?.interfaceName

    static func friendlyName(for name: String) -> String {
        if let wifi = wifiBSDName, wifi == name {
            return "Wi‑Fi (\(name))"
        }
        if name.hasPrefix("en") {
            return "Ethernet (\(name))"
        }
        if name.hasPrefix("utun") {
            return "VPN (\(name))"
        }
        if name.hasPrefix("awdl") {
            return "AirDrop (\(name))"
        }
        if name.hasPrefix("llw") {
            return "Low‑Latency Wireless (\(name))"
        }
        if name.hasPrefix("bridge") {
            return "Bridge (\(name))"
        }
        if name.hasPrefix("ap") {
            return "Personal Hotspot (\(name))"
        }
        if name.hasPrefix("p2p") {
            return "Peer‑to‑Peer (\(name))"
        }
        return name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if interfaces.isEmpty {
                Text("No interfaces detected right now.")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                ForEach(interfaces, id: \.self) { name in
                    Toggle(isOn: Binding(get: {
                        selected.contains(name)
                    }, set: { newVal in
                        if newVal {
                            selected.insert(name)
                        } else {
                            selected.remove(name)
                        }
                    })) {
                        Text(InterfacePickerView.friendlyName(for: name))
                    }
                }
            }
            Button("Refresh Interfaces") {
                interfaces = InterfacePickerView.fetchInterfaces()
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
        .onAppear {
            interfaces = InterfacePickerView.fetchInterfaces()
        }
    }
    
    static func fetchInterfaces() -> [String] {
        var names: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let flags = Int32(ptr!.pointee.ifa_flags)
                if (flags & (IFF_UP|IFF_RUNNING) == (IFF_UP|IFF_RUNNING)) && (flags & IFF_LOOPBACK == 0) {
                    if let c = ptr!.pointee.ifa_name {
                        let name = String(cString: c)
                        if !names.contains(name) {
                            names.append(name)
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return names.sorted()
    }
}

@main
struct MenuBarBandwidthMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            SettingsView()
                .frame(width: 420, height: 220)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var monitor: BandwidthMonitor!
    var timerCancellable: AnyCancellable?
    var detailsPopover: NSPopover?
    var aboutWindowController: NSWindowController?
    var tipWindowController: NSWindowController?
    var settingsWindowController: NSWindowController?

    let tipJarManager = TipJarManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "runAsHiddenService") {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }

        tipJarManager.startListeningForTransactions()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Use monospaced digits for stable width and native appearance
        if let button = statusItem.button {
            let size = button.font?.pointSize ?? NSFont.systemFontSize
            button.font = NSFont.monospacedDigitSystemFont(ofSize: size, weight: .regular)
            button.setAccessibilityLabel("Bandwidth Monitor")
        }
        statusItem.button?.title = "…"
        statusItem.button?.toolTip = "Bandwidth monitor"

        // Fix the status item width based on a max-width template and center the text
        if let button = statusItem.button {
            let font = button.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]

            // Consider a few widest templates for bits and bytes modes; take the maximum width
            let templates = [
                "↓ 88888 Mbps ↑ 88888 Mbps",
                "↓ 88888 Gbps ↑ 88888 Gbps",
                "↓ 88888 kB/s ↑ 88888 kB/s",
                "↓ 88888 MB/s ↑ 88888 MB/s",
                "↓ 88888 GB/s ↑ 88888 GB/s"
            ]
            var maxWidth: CGFloat = 0
            for t in templates { let w = (t as NSString).size(withAttributes: attributes).width; if w > maxWidth { maxWidth = w } }
            let padding: CGFloat = 20.0
            statusItem.length = ceil(maxWidth + padding)

            // Center the text within the fixed-width button
            button.alignment = .center
            button.lineBreakMode = .byTruncatingMiddle
            button.cell?.wraps = false
        }

        // Menu: About, Open Statistics, Settings, Tip Jar, separator, Quit
        let menu = NSMenu()

        let aboutItem = NSMenuItem(title: "About Bandwidth Monitor", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let openStatsItem = NSMenuItem(title: "Open Statistics", action: #selector(openDetails), keyEquivalent: "")
        openStatsItem.target = self
        menu.addItem(openStatsItem)

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let tipJarItem = NSMenuItem(title: "Tip Jar…", action: #selector(showTipJar), keyEquivalent: "")
        tipJarItem.target = self
        menu.addItem(tipJarItem)

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
                let title = "↓ \(rates.download) ↑ \(rates.upload)"
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
                        let boldFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .bold)
                        for match in regex.matches(in: subString, range: subRange) {
                            let adjusted = NSRange(location: range.location + match.range.location, length: match.range.length)
                            attributed.addAttribute(.font, value: boldFont, range: adjusted)
                        }
                    }
                }

                // Default attributes
                fullString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
                fullString.addAttribute(.font, value: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular), range: fullRange)

                // Find range of download part: "↓ \(rates.download)"
                let downloadString = "↓ \(rates.download)"
                if let downloadRange = title.range(of: downloadString) {
                    let nsDownloadRange = NSRange(downloadRange, in: title)
                    fullString.addAttribute(.foregroundColor, value: darkGreen, range: nsDownloadRange)
                    // Bold the numeric portion of the download string
                    boldNumbers(in: fullString, title: title, range: nsDownloadRange)
                }

                // Find range of upload part: "↑ \(rates.upload)"
                let uploadString = "↑ \(rates.upload)"
                if let uploadRange = title.range(of: uploadString) {
                    let nsUploadRange = NSRange(uploadRange, in: title)
                    fullString.addAttribute(.foregroundColor, value: NSColor.systemRed, range: nsUploadRange)
                    // Bold the numeric portion of the upload string
                    boldNumbers(in: fullString, title: title, range: nsUploadRange)
                }

                // Set the attributed string to statusItem.button
                self.statusItem.button?.attributedTitle = fullString
                // self.statusItem.button?.title = title // old line commented out

                self.statusItem.button?.toolTip = "Download: \(rates.download)\nUpload: \(rates.upload)"
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

    @objc func showTipJar(_ sender: Any?) {
        if let win = tipWindowController, win.window?.isVisible == true {
            win.window?.makeKeyAndOrderFront(nil)
            return
        }
        let contentView = TipJarView(manager: tipJarManager) { [weak self] in
            self?.tipWindowController?.close()
            self?.tipWindowController = nil
        }
        let hosting = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Tip Jar"
        window.setContentSize(NSSize(width: 380, height: 260))
        window.contentMinSize = NSSize(width: 340, height: 220)
        window.styleMask.insert([.titled, .closable, .resizable])
        window.isReleasedWhenClosed = false
        let controller = NSWindowController(window: window)
        self.tipWindowController = controller
        controller.showWindow(self)
        window.center()
    }

    @objc func showSettings(_ sender: Any?) {
        if let win = settingsWindowController, win.window?.isVisible == true {
            win.window?.makeKeyAndOrderFront(nil)
            return
        }
        let contentView = SettingsView { [weak self] in
            self?.settingsWindowController?.close()
            self?.settingsWindowController = nil
        }
        let hosting = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Settings"
        window.setContentSize(NSSize(width: 420, height: 220))
        window.contentMinSize = NSSize(width: 380, height: 200)
        window.styleMask.insert([.titled, .closable, .resizable])
        window.isReleasedWhenClosed = false
        let controller = NSWindowController(window: window)
        self.settingsWindowController = controller
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

struct BandwidthRates: Sendable {
    var download: String
    var upload: String
    var timestamp: Date // Add this field
}

private struct HistorySample: Sendable {
    let timestamp: Date
    let rx: UInt64
    let tx: UInt64
}

private struct PersistedData: Sendable {
    let history: [HistorySample]
    let totalDownloadAllTime: UInt64
    let totalUploadAllTime: UInt64
}

nonisolated(unsafe) extension HistorySample: Codable {}
nonisolated(unsafe) extension PersistedData: Codable {}

final class BandwidthMonitor: ObservableObject {
    @Published var rates = BandwidthRates(download: "0 Mbps", upload: "0 Mbps", timestamp: Date())
    @Published var recentSamples: [(time: Date, down: UInt64, up: UInt64, dt: TimeInterval)] = []
    @Published var peakDownPerSecondBytes: Double = 0
    @Published var peakUpPerSecondBytes: Double = 0
    
    private var timer: Timer?
    private var prevRx: UInt64 = 0
    private var prevTx: UInt64 = 0
    private var lastInterfaceSet: Set<String> = []
    private var isFirstSample = true
    // Store history as array of HistorySample for codable persistence
    private var history: [HistorySample] = []
    
    private var totalDownloadAllTime: UInt64 = 0
    private var totalUploadAllTime: UInt64 = 0
    
    private let prefs = Preferences.shared
    
    private var lastSampleDate: Date?
    private var lastSaveDate: Date = .distantPast
    private var samplingCancellable: AnyCancellable?
    
    // Expose as a property
    var totalsAllTime: (download: UInt64, upload: UInt64) {
        (totalDownloadAllTime, totalUploadAllTime)
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
        samplingCancellable = Preferences.shared.$samplingInterval
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.rescheduleTimerIfNeeded()
            }
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: prefs.samplingInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        saveHistory() // Save the history when stopping monitoring
    }
    
    private func rescheduleTimerIfNeeded() {
        let interval = prefs.samplingInterval
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: max(0.25, interval), repeats: true) { [weak self] _ in
            self?.poll()
        }
    }
    
    private func poll() {
        let now = Date()
        let (rx, tx, names) = getNetworkBytes()
        if isFirstSample {
            prevRx = rx
            prevTx = tx
            lastSampleDate = now
            lastInterfaceSet = names
            isFirstSample = false
            return
        }
        let elapsed = max(0.001, now.timeIntervalSince(lastSampleDate ?? now))
        lastSampleDate = now
        
        // Detect interface set changes to avoid over-counting when counters reset or interfaces change
        var interfaceSetChanged = false
        if lastInterfaceSet != names {
            interfaceSetChanged = true
            lastInterfaceSet = names
        }
        
        // Handle counter wraparound (interface reset or overflow) and interface set changes
        let rawDeltaRx: UInt64 = rx >= prevRx ? rx &- prevRx : rx
        let rawDeltaTx: UInt64 = tx >= prevTx ? tx &- prevTx : tx
        let deltaRx: UInt64 = interfaceSetChanged ? 0 : rawDeltaRx
        let deltaTx: UInt64 = interfaceSetChanged ? 0 : rawDeltaTx
        
        prevRx = rx
        prevTx = tx

        // Increment totals all time
        totalDownloadAllTime &+= deltaRx
        totalUploadAllTime &+= deltaTx
        
        // Append new sample to history with current timestamp and byte counters
        history.append(HistorySample(timestamp: now, rx: rx, tx: tx))
        // Remove old samples beyond 35 days to keep history size manageable
        let cutoff = now.addingTimeInterval(-35 * 86400)
        history.removeAll { $0.timestamp < cutoff }
        saveHistoryIfNeeded() // Persist updated history to disk (throttled)
        
        recentSamples.append((time: now, down: deltaRx, up: deltaTx, dt: elapsed))
        let cutoffRecent = now.addingTimeInterval(-300)
        recentSamples.removeAll { $0.time < cutoffRecent }
        
        let currentDownPerSecond = Double(deltaRx) / elapsed
        let currentUpPerSecond = Double(deltaTx) / elapsed
        DispatchQueue.main.async {
            if currentDownPerSecond > self.peakDownPerSecondBytes { self.peakDownPerSecondBytes = currentDownPerSecond }
            if currentUpPerSecond > self.peakUpPerSecondBytes { self.peakUpPerSecondBytes = currentUpPerSecond }
        }

        DispatchQueue.main.async {
            self.rates = BandwidthRates(
                download: Self.format(bytes: deltaRx, over: elapsed),
                upload: Self.format(bytes: deltaTx, over: elapsed),
                timestamp: now
            )
        }
    }
    
    private func getPerInterfaceBytes() -> [(name: String, rx: UInt64, tx: UInt64)] {
        var results: [(String, UInt64, UInt64)] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let flags = Int32(ptr!.pointee.ifa_flags)
                if (flags & (IFF_UP|IFF_RUNNING) == (IFF_UP|IFF_RUNNING)) && (flags & IFF_LOOPBACK == 0) {
                    if let nameC = ptr!.pointee.ifa_name {
                        let name = String(cString: nameC)
                        if let data = unsafeBitCast(ptr!.pointee.ifa_data, to: UnsafeMutablePointer<if_data>?.self) {
                            let rx = UInt64(data.pointee.ifi_ibytes)
                            let tx = UInt64(data.pointee.ifi_obytes)
                            results.append((name, rx, tx))
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return results
    }
    
    private func getNetworkBytes() -> (UInt64, UInt64, Set<String>) {
        let interfaces = getPerInterfaceBytes()
        let selected = Preferences.shared.selectedInterfaces
        let ignoredPrefixes = ["awdl", "llw", "utun", "bridge", "ap", "p2p"]
        let filtered: [(name: String, rx: UInt64, tx: UInt64)]
        if selected.isEmpty {
            filtered = interfaces.filter { tuple in
                !ignoredPrefixes.contains(where: { tuple.name.hasPrefix($0) })
            }
        } else {
            filtered = interfaces.filter { selected.contains($0.name) }
        }
        let rx = filtered.reduce(0) { $0 &+ $1.rx }
        let tx = filtered.reduce(0) { $0 &+ $1.tx }
        let names = Set(filtered.map { $0.name })
        return (rx, tx, names)
    }
    
    static func format(bytes: UInt64) -> String {
        let prefs = Preferences.shared
        let unitFactor: Double = prefs.useSIUnits ? 1000.0 : 1024.0
        if prefs.showBitsPerSecond {
            let rate = Double(bytes) * 8.0 / prefs.samplingInterval
            let units = ["bps","kbps","Mbps","Gbps","Tbps"]
            var value = rate
            var idx = 0
            while value >= unitFactor && idx < units.count - 1 {
                value /= unitFactor
                idx += 1
            }
            let fmt = idx <= 1 ? "%.0f %@" : "%.2f %@"
            return String(format: fmt, value, units[idx])
        } else {
            let rate = Double(bytes) / prefs.samplingInterval
            let units = ["B/s","kB/s","MB/s","GB/s","TB/s"]
            var value = rate
            var idx = 0
            while value >= unitFactor && idx < units.count - 1 {
                value /= unitFactor
                idx += 1
            }
            let fmt = idx <= 1 ? "%.0f %@" : "%.2f %@"
            return String(format: fmt, value, units[idx])
        }
    }

    static func format(bytes: UInt64, over interval: TimeInterval) -> String {
        let prefs = Preferences.shared
        let unitFactor: Double = prefs.useSIUnits ? 1000.0 : 1024.0
        if prefs.showBitsPerSecond {
            var value = (Double(bytes) * 8.0) / interval
            let units = ["bps","kbps","Mbps","Gbps","Tbps"]
            var idx = 0
            while value >= unitFactor && idx < units.count - 1 { value /= unitFactor; idx += 1 }
            let fmt = idx <= 1 ? "%.0f %@" : "%.2f %@"
            return String(format: fmt, value, units[idx])
        } else {
            var value = Double(bytes) / interval
            let units = ["B/s","kB/s","MB/s","GB/s","TB/s"]
            var idx = 0
            while value >= unitFactor && idx < units.count - 1 { value /= unitFactor; idx += 1 }
            let fmt = idx <= 1 ? "%.0f %@" : "%.2f %@"
            return String(format: fmt, value, units[idx])
        }
    }
    
    // Formats a raw byte total into human-readable units (kB, MB, GB, TB) using decimal or binary units.
    static func formatTotal(bytes: UInt64) -> String {
        let prefs = Preferences.shared
        let factor: Double = prefs.useSIUnits ? 1000.0 : 1024.0
        let suffixes = prefs.useSIUnits ? ["B","kB","MB","GB","TB"] : ["B","KiB","MiB","GiB","TiB"]
        var value = Double(bytes)
        var idx = 0
        while value >= factor && idx < suffixes.count - 1 {
            value /= factor
            idx += 1
        }
        let fmt = idx <= 1 ? "%.0f %@" : "%.2f %@"
        return String(format: fmt, value, suffixes[idx])
    }
    
    private func saveHistoryIfNeeded() {
        let now = Date()
        if now.timeIntervalSince(lastSaveDate) >= 15 {
            saveHistory()
            lastSaveDate = now
        }
    }
    
    // Save history array as JSON to disk atomically off main thread
    private func saveHistory() {
        // Take a main-actor snapshot of data that may be mutated on the main thread
        let snapshot: PersistedData = {
            let historyCopy = self.history
            let dl = self.totalDownloadAllTime
            let ul = self.totalUploadAllTime
            return PersistedData(history: historyCopy, totalDownloadAllTime: dl, totalUploadAllTime: ul)
        }()

        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: self.historyURL, options: .atomic)
            } catch {
                // ignore errors
            }
        }
    }
    
    // Load history array from JSON file on disk, filtering out old samples
    private func loadHistory() {
        do {
            let data = try Data(contentsOf: historyURL)
            if let object = try? JSONDecoder().decode(PersistedData.self, from: data) {
                let dayAgo = Date().addingTimeInterval(-35 * 86400)
                let filteredHistory = object.history.filter { $0.timestamp >= dayAgo }
                DispatchQueue.main.async {
                    self.history = filteredHistory
                    self.totalDownloadAllTime = object.totalDownloadAllTime
                    self.totalUploadAllTime = object.totalUploadAllTime
                }
            } else if let old = try? JSONDecoder().decode([HistorySample].self, from: data) {
                let dayAgo = Date().addingTimeInterval(-35 * 86400)
                let filteredHistory = old.filter { $0.timestamp >= dayAgo }
                DispatchQueue.main.async {
                    self.history = filteredHistory
                    self.totalDownloadAllTime = 0
                    self.totalUploadAllTime = 0
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.history = []
                self.totalDownloadAllTime = 0
                self.totalUploadAllTime = 0
            }
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
            self.peakDownPerSecondBytes = 0
            self.peakUpPerSecondBytes = 0
            self.saveHistory()
            self.rates = BandwidthRates(download: "0 Mbps", upload: "0 Mbps", timestamp: Date())
        }
    }
    
    private func currentCycleStart(now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let prefs = Preferences.shared
        let billingDay = max(1, min(28, prefs.billingDay))
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        if let day = components.day, day < billingDay {
            // Cycle started last month
            let prev = calendar.date(byAdding: .month, value: -1, to: now)!
            var prevComp = calendar.dateComponents([.year, .month], from: prev)
            prevComp.day = billingDay
            return calendar.date(from: prevComp) ?? calendar.startOfDay(for: prev)
        } else {
            // Cycle started this month
            var thisComp = calendar.dateComponents([.year, .month], from: now)
            thisComp.day = billingDay
            return calendar.date(from: thisComp) ?? calendar.startOfDay(for: now)
        }
    }

    var totalsCurrentCycle: (download: UInt64, upload: UInt64) {
        let start = currentCycleStart()
        var totalRx: UInt64 = 0
        var totalTx: UInt64 = 0
        func safeDelta(newer: UInt64, older: UInt64) -> UInt64 {
            if newer >= older { return newer &- older } else { return newer }
        }
        for i in 1..<history.count {
            let t0 = history[i-1]
            let t1 = history[i]
            if t1.timestamp >= start {
                totalRx &+= safeDelta(newer: t1.rx, older: t0.rx)
                totalTx &+= safeDelta(newer: t1.tx, older: t0.tx)
            }
        }
        return (totalRx, totalTx)
    }
}

struct BandwidthTotalsView: View {
    @ObservedObject var monitor: BandwidthMonitor
    @State private var showResetAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Total Data Since Last Reset")
                .font(.title2).bold()
            
            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(monitor.recentSamples, id: \.time) { sample in
                        LineMark(x: .value("Time", sample.time), y: .value("Down", Double(sample.down) / sample.dt))
                            .foregroundStyle(.green)
                        LineMark(x: .value("Time", sample.time), y: .value("Up", Double(sample.up) / sample.dt))
                            .foregroundStyle(.red)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 80)
            } else {
                SparklineView(samples: monitor.recentSamples.map { (time: $0.time, down: Double($0.down) / $0.dt, up: Double($0.up) / $0.dt) })
                    .frame(height: 80)
            }
            
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Peak Rates (since launch/reset)").font(.headline)
                HStack {
                    Text("Down:")
                    Text(BandwidthMonitor.format(bytes: UInt64(monitor.peakDownPerSecondBytes), over: 1.0))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.green)
                    Spacer()
                    Text("Up:")
                    Text(BandwidthMonitor.format(bytes: UInt64(monitor.peakUpPerSecondBytes), over: 1.0))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
            
            if Preferences.shared.dataCapEnabled {
                let cycle = monitor.totalsCurrentCycle
                let capBytes = UInt64(Preferences.shared.dataCapGB * 1000 * 1000 * 1000)
                let usedBytes = cycle.download &+ cycle.upload
                let remaining = capBytes > usedBytes ? capBytes &- usedBytes : 0
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Cycle Usage").font(.headline)
                    Text("Used: \(BandwidthMonitor.formatTotal(bytes: usedBytes))  •  Remaining: \(BandwidthMonitor.formatTotal(bytes: remaining))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            
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
        .frame(width: 320, height: 320)
        .padding(18)
    }
}

struct SparklineView: View {
    let samples: [(time: Date, down: Double, up: Double)]
    var body: some View {
        GeometryReader { geo in
            let pointsDown = SparklineView.normalize(samples.map { $0.down }, width: geo.size.width, height: geo.size.height)
            let pointsUp = SparklineView.normalize(samples.map { $0.up }, width: geo.size.width, height: geo.size.height)
            ZStack {
                Path { path in
                    guard !pointsDown.isEmpty else { return }
                    path.move(to: pointsDown[0])
                    for p in pointsDown.dropFirst() {
                        path.addLine(to: p)
                    }
                }
                .stroke(Color.green, lineWidth: 1)
                Path { path in
                    guard !pointsUp.isEmpty else { return }
                    path.move(to: pointsUp[0])
                    for p in pointsUp.dropFirst() {
                        path.addLine(to: p)
                    }
                }
                .stroke(Color.red, lineWidth: 1)
            }
        }
    }
    static func normalize(_ values: [Double], width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let maxV = max(values.max() ?? 1, 1)
        let stepX = width / CGFloat(max(values.count - 1, 1))
        return values.enumerated().map { (idx, v) in
            let x = CGFloat(idx) * stepX
            let y = height - CGFloat(v / maxV) * height
            return CGPoint(x: x, y: y)
        }
    }
}

