// MenuBarBandwidthMonitor.swift


import SwiftUI
import Combine
import AppKit
import StoreKit
import ServiceManagement
import Charts // Optional: for macOS 13+
import CoreWLAN
import SystemConfiguration
import UserNotifications
import WidgetKit

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
        .themedBackground()
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @ObservedObject private var prefs = Preferences.shared
    @State private var page: Int = 0
    var onFinish: (() -> Void)?

    // Page 0: language, 1: welcome, 2: theme, 3: units, 4: dataCap, 5: notifications, 6: finish
    private let totalPages = 7

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            Group {
                switch page {
                case 0: languagePage
                case 1: welcomePage
                case 2: themePage
                case 3: unitsPage
                case 4: dataCapPage
                case 5: notificationsPage
                case 6: finishPage
                default: languagePage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Navigation bar
            HStack {
                // Step dots
                HStack(spacing: 6) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Color.accentColor : Color.secondary.opacity(0.35))
                            .frame(width: 7, height: 7)
                    }
                }

                Spacer()

                if page > 0 {
                    Button(L.back) { page -= 1 }
                        .buttonStyle(.bordered)
                }

                if page < totalPages - 1 {
                    Button(L.next) { page += 1 }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button(L.getStarted) { onFinish?() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .frame(width: 480, height: 380)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: Pages

    private var languagePage: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundStyle(.tint)

            Text(L.chooseLanguage)
                .font(.title2).bold()

            Text(L.chooseLanguageDesc)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 10) {
                ForEach(Preferences.Language.allCases) { lang in
                    Button {
                        prefs.language = lang
                    } label: {
                        HStack(spacing: 12) {
                            Text(lang.flag)
                                .font(.title2)
                            Text(lang.displayName)
                                .font(.body)
                                .fontWeight(prefs.language == lang ? .semibold : .regular)
                            Spacer()
                            if prefs.language == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(prefs.language == lang
                                      ? Color.accentColor.opacity(0.12)
                                      : Color(nsColor: .controlBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(prefs.language == lang ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 48)
        }
        .padding(32)
    }

    private var welcomePage: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundStyle(.tint)

            Text(L.welcomeTitle)
                .font(.title).bold()
                .multilineTextAlignment(.center)

            // "New version" badge
            Text(L.majorUpdate)
                .font(.caption).bold()
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.accentColor, in: Capsule())

            Text(L.welcomeBody)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            VStack(alignment: .leading, spacing: 5) {
                Label(L.welcomeBullet1, systemImage: "bell.badge.fill")
                Label(L.welcomeBullet2, systemImage: "globe")
                Label(L.welcomeBullet3, systemImage: "moon.fill")
                Label(L.welcomeBullet4, systemImage: "bolt.horizontal.fill")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text(L.welcomeFooter)
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
    }

    private var themePage: some View {
        VStack(spacing: 20) {
            Image(systemName: "paintbrush.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(.tint)

            Text(L.chooseStyle)
                .font(.title2).bold()

            Text(L.chooseStyleDesc)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                ForEach(Preferences.Theme.allCases) { theme in
                    Button {
                        prefs.theme = theme
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(theme == .translucent ? Color.clear : Color(nsColor: .windowBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(prefs.theme == theme ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: prefs.theme == theme ? 2 : 1)
                                    )
                                    .frame(width: 120, height: 64)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

                                Text("↓ 12 Mbps ↑ 2 Mbps")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(theme == .solid ? .primary : .primary)
                            }
                            Text(theme == .translucent ? L.themeTranslucent : L.themeSolid)
                                .font(.subheadline)
                                .fontWeight(prefs.theme == theme ? .semibold : .regular)
                                .foregroundStyle(prefs.theme == theme ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(32)
    }

    private var unitsPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "ruler.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(.tint)

            Text(L.unitsTitle)
                .font(.title2).bold()

            Text(L.unitsDesc)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(isOn: $prefs.showBitsPerSecond) {
                        Text(L.showBitsPerSecondToggle)
                            .font(.body)
                    }
                    Text(prefs.showBitsPerSecond ? L.showBitsDesc_on : L.showBitsDesc_off)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Toggle(isOn: $prefs.useSIUnits) {
                        Text(L.useSIUnitsToggle)
                            .font(.body)
                    }
                    Text(prefs.useSIUnits ? L.siUnitsDesc_on : L.siUnitsDesc_off)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)
        }
        .padding(32)
    }

    private var dataCapPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "gauge.with.needle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(.tint)

            Text(L.monthlyDataCap)
                .font(.title2).bold()

            Text(L.dataCapDesc)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $prefs.dataCapEnabled) {
                    Text(L.enableDataCapTracking)
                        .font(.body)
                }

                if prefs.dataCapEnabled {
                    HStack {
                        Text(L.monthlyCap)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { Int(prefs.dataCapGB) },
                            set: { prefs.dataCapGB = Double($0) }
                        )) {
                            ForEach([10, 25, 50, 100, 150, 200, 250, 300, 500, 750, 1000], id: \.self) { gb in
                                Text("\(gb) GB").tag(gb)
                            }
                        }
                        .frame(width: 110)
                    }

                    HStack {
                        Text(L.billingStartsOnDay)
                        Spacer()
                        Picker("", selection: $prefs.billingDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .frame(width: 80)
                    }
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            .animation(.easeInOut(duration: 0.2), value: prefs.dataCapEnabled)
            .padding(.horizontal, 24)
        }
        .padding(32)
    }

    private var notificationsPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(.tint)

            Text(L.notificationsTitle)
                .font(.title2).bold()

            Text(L.notificationsDesc)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            VStack(spacing: 10) {
                Button(L.allowNotifications) {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                        if granted {
                            DispatchQueue.main.async { page += 1 }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                Text(L.notificationsSystemHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(32)
    }

    private var finishPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundStyle(.green)

            Text(L.allSet)
                .font(.title).bold()

            VStack(alignment: .leading, spacing: 8) {
                Label(L.finishBullet1, systemImage: "arrow.up.arrow.down")
                Label(L.finishBullet2, systemImage: "chart.bar.fill")
                Label(L.finishBullet3, systemImage: "gearshape.fill")
                if prefs.dataCapEnabled {
                    Label(L.finishBullet4, systemImage: "bell.fill")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 32)

            Text(L.tipJarHint)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 4)
        }
        .padding(32)
    }
}

// Helper ViewModifier to apply background based on theme
struct ThemedBackground: ViewModifier {
    @ObservedObject private var prefs = Preferences.shared
    func body(content: Content) -> some View {
        switch prefs.theme {
        case .translucent:
            content.background(.ultraThinMaterial)
        case .solid:
            content.background(Color(nsColor: .windowBackgroundColor)).ignoresSafeArea()
        case .dark:
            content.background(Color(nsColor: .controlBackgroundColor)).ignoresSafeArea()
        }
    }
}

extension View {
    func themedBackground() -> some View { self.modifier(ThemedBackground()) }
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
        .themedBackground()
        .task { await manager.load() }
    }
}

// MARK: - Preferences & Settings
final class Preferences: ObservableObject {
    static let shared = Preferences()
    
    enum Theme: String, CaseIterable, Identifiable {
        case translucent
        case solid
        case dark
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .translucent: return "Translucent"
            case .solid:       return "Solid"
            case .dark:        return "Dark"
            }
        }
    }
    
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
    @Published var theme: Theme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "themePreference") }
    }

    enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case french  = "fr"
        case german  = "de"
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .english: return "English"
            case .french:  return "Français"
            case .german:  return "Deutsch"
            }
        }
        var flag: String {
            switch self {
            case .english: return "🇬🇧"
            case .french:  return "🇫🇷"
            case .german:  return "🇩🇪"
            }
        }
    }

    @Published var language: Language {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
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
        
        if let raw = UserDefaults.standard.string(forKey: "themePreference"), let t = Theme(rawValue: raw) {
            self.theme = t
        } else {
            self.theme = .translucent
        }

        if let raw = UserDefaults.standard.string(forKey: "appLanguage"), let lang = Language(rawValue: raw) {
            self.language = lang
        } else {
            // Default to system language if supported, otherwise English
            let sysLang = Locale.current.language.languageCode?.identifier ?? "en"
            self.language = Language(rawValue: sysLang) ?? .english
        }
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

// MARK: - Localisation
struct L {
    static var lang: Preferences.Language { Preferences.shared.language }

    // MARK: General / Navigation
    static var settings: String          { tr("Settings",         "Paramètres",        "Einstellungen") }
    static var close: String             { tr("Close",            "Fermer",             "Schließen") }
    static var back: String              { tr("Back",             "Retour",             "Zurück") }
    static var next: String              { tr("Next",             "Suivant",            "Weiter") }
    static var getStarted: String        { tr("Get Started",      "Commencer",          "Los geht's") }

    // MARK: Settings – General
    static var launchAtLogin: String     { tr("Launch at login",  "Démarrer à l'ouverture de session", "Beim Anmelden starten") }
    static var launchAtLoginDesc: String { tr("Automatically start Bandwidth Monitor when you sign in.",
                                              "Lancer automatiquement Bandwidth Monitor à l'ouverture de session.",
                                              "Bandwidth Monitor beim Anmelden automatisch starten.") }
    static var runAsHiddenService: String     { tr("Run as hidden service",   "Exécuter en tant que service caché",   "Als versteckten Dienst ausführen") }
    static var runAsHiddenServiceDesc: String { tr("Hide the Dock icon and run in the background. Requires relaunch.",
                                                   "Masquer l'icône du Dock et s'exécuter en arrière-plan. Nécessite un redémarrage.",
                                                   "Dock-Symbol ausblenden und im Hintergrund laufen. Neustart erforderlich.") }

    // MARK: Settings – Monitoring
    static var monitoring: String        { tr("Monitoring",       "Surveillance",       "Überwachung") }
    static var samplingInterval: String  { tr("Sampling interval","Intervalle d'échantillonnage", "Abtastintervall") }
    static var showBitsPerSecond: String { tr("Show bits per second (instead of bytes)", "Afficher les bits par seconde (au lieu des octets)", "Bits pro Sekunde anzeigen (statt Bytes)") }
    static var useSIUnits: String        { tr("Use SI units (1000) instead of IEC (1024)", "Utiliser les unités SI (1000) au lieu de IEC (1024)", "SI-Einheiten (1000) statt IEC (1024) verwenden") }

    // MARK: Settings – Appearance
    static var appearance: String        { tr("Appearance",       "Apparence",          "Erscheinungsbild") }
    static var theme: String             { tr("Theme",            "Thème",              "Design") }
    static var themeTranslucent: String  { tr("Translucent",      "Translucide",        "Durchsichtig") }
    static var themeSolid: String        { tr("Solid",            "Solide",             "Massiv") }

    // MARK: Settings – Interfaces
    static var interfaces: String        { tr("Interfaces",       "Interfaces",         "Schnittstellen") }
    static var interfacesDesc: String    { tr("Select interfaces to include. Leave empty to include all.",
                                              "Sélectionnez les interfaces à inclure. Laissez vide pour toutes les inclure.",
                                              "Schnittstellen auswählen. Leer lassen, um alle einzuschließen.") }
    static var noInterfacesDetected: String { tr("No interfaces detected right now.",
                                                 "Aucune interface détectée pour l'instant.",
                                                 "Derzeit keine Schnittstellen erkannt.") }
    static var refreshInterfaces: String { tr("Refresh Interfaces", "Actualiser les interfaces", "Schnittstellen aktualisieren") }

    // MARK: Settings – Data Cap
    static var dataCap: String               { tr("Data Cap",                   "Limite de données",        "Datenlimit") }
    static var enableDataCap: String         { tr("Enable monthly data cap tracking", "Activer le suivi de la limite mensuelle", "Monatliches Datenlimit aktivieren") }
    static var capSize: String               { tr("Cap size",                   "Taille limite",            "Limitgröße") }
    static var billingDay: String            { tr("Billing day",                "Jour de facturation",      "Abrechnungstag") }
    static var testNotification: String      { tr("Test Notification",          "Tester la notification",   "Benachrichtigung testen") }
    static var relaunchNow: String           { tr("Relaunch Now",               "Relancer maintenant",      "Jetzt neu starten") }
    static var relaunchHint: String          { tr("Please quit and reopen the app to apply this change.",
                                                   "Veuillez quitter et rouvrir l'application pour appliquer ce changement.",
                                                   "Bitte App beenden und neu öffnen, um die Änderung anzuwenden.") }

    // MARK: Settings – Language
    static var language: String          { tr("Language",         "Langue",             "Sprache") }

    // MARK: Onboarding – Language picker
    static var chooseLanguage: String    { tr("Choose Your Language",  "Choisissez votre langue",  "Sprache wählen") }
    static var chooseLanguageDesc: String { tr("Select the language you'd like to use throughout the app.",
                                               "Sélectionnez la langue que vous souhaitez utiliser dans l'application.",
                                               "Wählen Sie die Sprache, die Sie in der App verwenden möchten.") }

    // MARK: Onboarding – Welcome
    static var welcomeTitle: String      { tr("Bandwidth Monitor 3.1",  "Bandwidth Monitor 3.1",  "Bandwidth Monitor 3.1") }
    static var majorUpdate: String       { tr("MAJOR UPDATE",           "MISE À JOUR MAJEURE",    "GROSSES UPDATE") }
    static var welcomeBody: String       { tr("A lot has changed since v2. We've added data cap notifications, language support, dark mode, a smarter interface picker, improved settings, and plenty of fixes — all while staying lightweight and private.",
                                              "Beaucoup de choses ont changé depuis la v2. Nous avons ajouté des notifications de limite de données, la prise en charge des langues, le mode sombre, un sélecteur d'interface plus intelligent et de nombreuses corrections — tout en restant léger et privé.",
                                              "Seit v2 hat sich viel geändert. Wir haben Datenlimit-Benachrichtigungen, Sprachunterstützung, Dark Mode, eine intelligentere Schnittstellenauswahl und viele Korrekturen hinzugefügt — alles bei minimalem Ressourcenverbrauch.") }
    static var welcomeBullet1: String    { tr("Data cap alerts at 75%, 90% and 100%",
                                              "Alertes de limite de données à 75 %, 90 % et 100 %",
                                              "Datenlimit-Warnungen bei 75 %, 90 % und 100 %") }
    static var welcomeBullet2: String    { tr("English, French & German language support",
                                              "Prise en charge de l'anglais, du français et de l'allemand",
                                              "Englisch, Französisch & Deutsch Sprachunterstützung") }
    static var welcomeBullet3: String    { tr("Dark mode theme option",
                                              "Option de thème sombre",
                                              "Dark-Mode-Theme-Option") }
    static var welcomeBullet4: String    { tr("Speed test shortcut & billing cycle up to day 31",
                                              "Raccourci test de vitesse & cycle de facturation jusqu'au jour 31",
                                              "Speedtest-Verknüpfung & Abrechnungszyklus bis Tag 31") }
    static var welcomeFooter: String     { tr("No accounts. No tracking. Everything stays on your Mac.",
                                              "Pas de comptes. Pas de suivi. Tout reste sur votre Mac.",
                                              "Keine Konten. Kein Tracking. Alles bleibt auf Ihrem Mac.") }

    // MARK: Onboarding – Theme
    static var chooseStyle: String       { tr("Choose a Style",     "Choisissez un style",     "Stil auswählen") }
    static var chooseStyleDesc: String   { tr("Pick how the menu bar display looks. You can change this at any time in Settings.",
                                              "Choisissez l'apparence de l'affichage dans la barre des menus. Vous pouvez le modifier à tout moment dans les Paramètres.",
                                              "Wählen Sie das Aussehen der Menüleiste. Sie können dies jederzeit in den Einstellungen ändern.") }

    // MARK: Onboarding – Units
    static var unitsTitle: String        { tr("Units & Display",   "Unités et affichage",    "Einheiten & Anzeige") }
    static var unitsDesc: String         { tr("Choose how speeds are shown in your menu bar.",
                                              "Choisissez comment les vitesses sont affichées dans votre barre des menus.",
                                              "Wählen Sie, wie Geschwindigkeiten in Ihrer Menüleiste angezeigt werden.") }
    static var showBitsDesc_on: String   { tr("Speeds shown as Mbps / Gbps — matches what ISPs advertise.",
                                              "Vitesses affichées en Mbit/s / Gbit/s — correspond à ce que les FAI annoncent.",
                                              "Geschwindigkeiten in Mbit/s / Gbit/s — entspricht ISP-Angaben.") }
    static var showBitsDesc_off: String  { tr("Speeds shown as MB/s / GB/s — matches file transfer speeds.",
                                              "Vitesses affichées en Mo/s / Go/s — correspond aux vitesses de transfert de fichiers.",
                                              "Geschwindigkeiten in MB/s / GB/s — entspricht Dateiübertragungsgeschwindigkeiten.") }
    static var siUnitsDesc_on: String    { tr("1 MB = 1,000,000 bytes — consistent with how ISPs and storage manufacturers measure.",
                                              "1 Mo = 1 000 000 octets — cohérent avec la mesure des FAI et fabricants de stockage.",
                                              "1 MB = 1.000.000 Byte — wie ISPs und Speicherhersteller messen.") }
    static var siUnitsDesc_off: String   { tr("1 MiB = 1,048,576 bytes — traditional binary units used by operating systems.",
                                              "1 Mio = 1 048 576 octets — unités binaires traditionnelles utilisées par les systèmes d'exploitation.",
                                              "1 MiB = 1.048.576 Byte — traditionelle Binäreinheiten der Betriebssysteme.") }
    static var showBitsPerSecondToggle: String { tr("Show bits per second",
                                                    "Afficher les bits par seconde",
                                                    "Bits pro Sekunde anzeigen") }
    static var useSIUnitsToggle: String  { tr("Use SI units (1000-based)",
                                              "Utiliser les unités SI (base 1000)",
                                              "SI-Einheiten verwenden (Basis 1000)") }

    // MARK: Onboarding – Data Cap
    static var monthlyDataCap: String    { tr("Monthly Data Cap",  "Limite de données mensuelle", "Monatliches Datenlimit") }
    static var dataCapDesc: String       { tr("If your ISP gives you a monthly allowance, Bandwidth Monitor can track your usage and warn you before you go over.",
                                              "Si votre FAI vous accorde un forfait mensuel, Bandwidth Monitor peut suivre votre utilisation et vous avertir avant de le dépasser.",
                                              "Wenn Ihr ISP ein monatliches Kontingent hat, kann Bandwidth Monitor Ihre Nutzung verfolgen und Sie warnen.") }
    static var enableDataCapTracking: String { tr("Enable data cap tracking",
                                                  "Activer le suivi de la limite de données",
                                                  "Datenlimit-Verfolgung aktivieren") }
    static var monthlyCap: String        { tr("Monthly cap",       "Forfait mensuel",    "Monatliches Limit") }
    static var billingStartsOnDay: String { tr("Billing starts on day", "Facturation à partir du jour", "Abrechnung ab Tag") }

    // MARK: Onboarding – Notifications
    static var notificationsTitle: String   { tr("Notifications",   "Notifications",     "Benachrichtigungen") }
    static var notificationsDesc: String    { tr("Bandwidth Monitor can alert you at 75%, 90%, and 100% of your monthly data cap. To enable alerts, grant notification permission when prompted.",
                                                 "Bandwidth Monitor peut vous alerter à 75 %, 90 % et 100 % de votre limite mensuelle. Pour activer les alertes, accordez la permission de notifications lorsque vous y êtes invité.",
                                                 "Bandwidth Monitor kann Sie bei 75 %, 90 % und 100 % Ihres Datenlimits warnen. Erlauben Sie Benachrichtigungen, wenn Sie dazu aufgefordert werden.") }
    static var allowNotifications: String   { tr("Allow Notifications",  "Autoriser les notifications",  "Benachrichtigungen erlauben") }
    static var notificationsSystemHint: String { tr("You can also enable notifications later via System Settings → Notifications → Bandwidth Monitor.",
                                                    "Vous pouvez également activer les notifications ultérieurement via Réglages Système → Notifications → Bandwidth Monitor.",
                                                    "Sie können Benachrichtigungen auch später über Systemeinstellungen → Mitteilungen → Bandwidth Monitor aktivieren.") }

    // MARK: Onboarding – Finish
    static var allSet: String            { tr("You're All Set!",   "C'est tout !",       "Alles bereit!") }
    static var finishBullet1: String     { tr("Speeds shown in your menu bar, always up to date",
                                              "Vitesses affichées dans votre barre des menus, toujours à jour",
                                              "Geschwindigkeiten in Ihrer Menüleiste, stets aktuell") }
    static var finishBullet2: String     { tr("Open Statistics from the menu to see usage history",
                                              "Ouvrez les Statistiques depuis le menu pour voir l'historique d'utilisation",
                                              "Öffnen Sie die Statistiken aus dem Menü, um den Verlauf zu sehen") }
    static var finishBullet3: String     { tr("Visit Settings anytime to adjust preferences",
                                              "Visitez les Paramètres à tout moment pour ajuster vos préférences",
                                              "Besuchen Sie jederzeit die Einstellungen, um Voreinstellungen anzupassen") }
    static var finishBullet4: String     { tr("You'll be notified at 75%, 90% and 100% of your cap",
                                              "Vous serez averti à 75 %, 90 % et 100 % de votre limite",
                                              "Sie werden bei 75 %, 90 % und 100 % Ihres Limits benachrichtigt") }
    static var tipJarHint: String        { tr("If you enjoy the app, a small tip via the Tip Jar helps keep it going.",
                                              "Si vous aimez l'application, un petit pourboire via la Tip Jar aide à la maintenir.",
                                              "Wenn Ihnen die App gefällt, hilft ein kleines Trinkgeld über das Tip Jar, sie am Laufen zu halten.") }

    // MARK: Statistics (BandwidthTotalsView)
    static var totalData: String         { tr("Total Data Since Last Reset",
                                              "Données totales depuis la dernière réinitialisation",
                                              "Gesamtdaten seit letztem Zurücksetzen") }
    static var download: String          { tr("Download",           "Téléchargement",    "Download") }
    static var upload: String            { tr("Upload",             "Téléversement",     "Upload") }
    static var peakRates: String         { tr("Peak Rates (since launch/reset)",
                                              "Vitesses de pointe (depuis le démarrage/réinitialisation)",
                                              "Spitzenraten (seit Start/Zurücksetzen)") }
    static var down: String              { tr("Down:",              "Bas :",              "Down:") }
    static var up: String                { tr("Up:",                "Haut :",             "Up:") }
    static var currentCycleUsage: String { tr("Current Cycle Usage", "Utilisation du cycle actuel", "Aktuelle Zyklusnutzung") }
    static var usedRemaining: String     { tr("Used",               "Utilisé",            "Genutzt") }
    static var remaining: String         { tr("Remaining",          "Restant",            "Verbleibend") }
    static var resetTotals: String       { tr("Reset Totals",       "Réinitialiser les totaux", "Statistiken zurücksetzen") }
    static var resetAlertTitle: String   { tr("Reset All Bandwidth Totals?",
                                              "Réinitialiser toutes les totaux de bande passante ?",
                                              "Alle Bandbreiten-Statistiken zurücksetzen?") }
    static var resetAlertMessage: String { tr("This will clear all statistics for the all-time totals. This cannot be undone.",
                                              "Cela effacera toutes les statistiques pour les totaux de tous les temps. Cette action est irréversible.",
                                              "Dadurch werden alle Statistiken der Gesamttotale gelöscht. Dies kann nicht rückgängig gemacht werden.") }
    static var resetConfirm: String      { tr("Reset",              "Réinitialiser",      "Zurücksetzen") }
    static var cancel: String            { tr("Cancel",             "Annuler",            "Abbrechen") }

    // MARK: Notification content
    static func capTitle(pct: Int) -> String {
        switch pct {
        case 100: return tr("Data Cap Reached",    "Limite de données atteinte",    "Datenlimit erreicht")
        default:  return tr("Data Cap: \(pct)% Used", "Limite de données : \(pct) % utilisés", "Datenlimit: \(pct) % genutzt")
        }
    }
    static func capBody(pct: Int, gb: Int) -> String {
        switch pct {
        case 100: return tr("You've reached your \(gb) GB monthly data cap.",
                            "Vous avez atteint votre limite mensuelle de \(gb) Go.",
                            "Sie haben Ihr monatliches Datenlimit von \(gb) GB erreicht.")
        default:  return tr("You've used \(pct)% of your \(gb) GB monthly allowance.",
                            "Vous avez utilisé \(pct) % de votre forfait mensuel de \(gb) Go.",
                            "Sie haben \(pct) % Ihres monatlichen Kontingents von \(gb) GB genutzt.")
        }
    }

    // MARK: Private helper
    private static func tr(_ en: String, _ fr: String, _ de: String) -> String {
        switch lang {
        case .english: return en
        case .french:  return fr
        case .german:  return de
        }
    }
}

struct SettingsView: View {
    let forceSolidBackground: Bool

    init(forceSolidBackground: Bool = false, onClose: (() -> Void)? = nil) {
        self.forceSolidBackground = forceSolidBackground
        self.onClose = onClose
    }

    @ObservedObject private var prefs = Preferences.shared
    var onClose: (() -> Void)?
    @State private var showRelaunchHint = false
    @State private var samplingIntervalText: String = ""
    @State private var dataCapGBText: String = ""

    var body: some View {
        if forceSolidBackground {
            settingsContent
                .background(Color(nsColor: .windowBackgroundColor))
                .ignoresSafeArea(edges: .all)
        } else {
            settingsContent
                .themedBackground()
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L.settings).font(.title2).bold()

            Toggle(isOn: Binding(
                get: { prefs.launchAtLogin },
                set: { newValue in
                    prefs.launchAtLogin = newValue
                }
            )) {
                VStack(alignment: .leading) {
                    Text(L.launchAtLogin)
                    Text(L.launchAtLoginDesc)
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
                    Text(L.runAsHiddenService)
                    Text(L.runAsHiddenServiceDesc)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L.monitoring).font(.headline)
                HStack(spacing: 8) {
                    Text(L.samplingInterval)
                    Spacer()
                    // Dropdown picker for common intervals 0.25s–30s
                    Picker("", selection: $prefs.samplingInterval) {
                        ForEach(Array(stride(from: 0.25, through: 30.0, by: 0.25)), id: \.self) { v in
                            Text(v.truncatingRemainder(dividingBy: 1) == 0
                                 ? String(format: "%.0f s", v)
                                 : String(format: "%.2g s", v)
                            ).tag(v)
                        }
                    }
                    .frame(width: 90)
                    // Text field for direct typed input
                    TextField("s", text: $samplingIntervalText)
                        .frame(width: 52)
                        .multilineTextAlignment(.trailing)
                        .onAppear { samplingIntervalText = String(format: "%.2g", prefs.samplingInterval) }
                        .onChange(of: prefs.samplingInterval) {
                            samplingIntervalText = String(format: "%.2g", prefs.samplingInterval)
                        }
                        .onSubmit {
                            if let v = Double(samplingIntervalText) {
                                prefs.samplingInterval = min(30.0, max(0.25, v))
                            }
                            samplingIntervalText = String(format: "%.2g", prefs.samplingInterval)
                        }
                    Text("s").foregroundStyle(.secondary)
                }
                Toggle(isOn: $prefs.showBitsPerSecond) {
                    Text(L.showBitsPerSecond)
                }
                Toggle(isOn: $prefs.useSIUnits) {
                    Text(L.useSIUnits)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L.appearance).font(.headline)
                Picker(L.theme, selection: $prefs.theme) {
                    ForEach(Preferences.Theme.allCases) { theme in
                        Text(theme == .translucent ? L.themeTranslucent : L.themeSolid).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L.interfaces).font(.headline)
                Text(L.interfacesDesc).font(.footnote).foregroundStyle(.secondary)
                InterfacePickerView(selected: $prefs.selectedInterfaces)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L.dataCap).font(.headline)
                Toggle(isOn: $prefs.dataCapEnabled) {
                    Text(L.enableDataCap)
                }
                HStack(spacing: 8) {
                    Text(L.capSize)
                    Spacer()
                    // Dropdown picker 1 GB – 1000 GB (1 TB)
                    Picker("", selection: Binding(
                        get: { Int(prefs.dataCapGB) },
                        set: { prefs.dataCapGB = Double($0) }
                    )) {
                        ForEach(1...1000, id: \.self) { gb in
                            Text("\(gb) GB").tag(gb)
                        }
                    }
                    .frame(width: 100)
                    // Text field for direct typed input
                    TextField("GB", text: $dataCapGBText)
                        .frame(width: 52)
                        .multilineTextAlignment(.trailing)
                        .onAppear { dataCapGBText = String(Int(prefs.dataCapGB)) }
                        .onChange(of: prefs.dataCapGB) {
                            dataCapGBText = String(Int(prefs.dataCapGB))
                        }
                        .onSubmit {
                            if let v = Double(dataCapGBText) {
                                prefs.dataCapGB = min(1000, max(1, v.rounded()))
                            }
                            dataCapGBText = String(Int(prefs.dataCapGB))
                        }
                    Text("GB").foregroundStyle(.secondary)
                }
                HStack {
                    Text(L.billingDay)
                    Spacer()
                    Picker(L.billingDay, selection: $prefs.billingDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .frame(width: 120)
                }
                Button(L.testNotification) {
                    let content = UNMutableNotificationContent()
                    content.title = "Notifications Working"
                    content.body = "Bandwidth Monitor notifications are set up correctly."
                    content.sound = .default
                    let request = UNNotificationRequest(identifier: "test.notification", content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request) { _ in }
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L.language).font(.headline)
                Picker("", selection: $prefs.language) {
                    ForEach(Preferences.Language.allCases) { lang in
                        Text("\(lang.flag) \(lang.displayName)").tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            if showRelaunchHint {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                    Text(L.relaunchHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            HStack {
                if showRelaunchHint {
                    Button(L.relaunchNow) {
                        relaunchApp()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer()
            HStack {
                Spacer()
                Button(L.close) { onClose?() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(18)
    }
    
    private func relaunchApp() {
        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in }
        NSApplication.shared.terminate(nil)
    }
}

struct InterfacePickerView: View {
    @Binding var selected: Set<String>
    @State private var interfaces: [String] = []
    
    // Maps BSD name (e.g. "en0") → system-provided localized display name (e.g. "Wi-Fi").
    // Built once from SCNetworkInterfaceCopyAll(), which is authoritative and locale-aware.
    private static let scDisplayNames: [String: String] = {
        var map: [String: String] = [:]
        let all = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] ?? []
        for iface in all {
            if let bsd = SCNetworkInterfaceGetBSDName(iface) as String?,
               let label = SCNetworkInterfaceGetLocalizedDisplayName(iface) as String? {
                map[bsd] = label
            }
        }
        return map
    }()

    static func friendlyName(for name: String) -> String {
        // Use the authoritative SC display name when available
        if let scName = scDisplayNames[name] {
            return "\(scName) (\(name))"
        }
        // Fallback labels for virtual/tunnel interfaces SC doesn't enumerate
        if name.hasPrefix("utun") { return "VPN (\(name))" }
        if name.hasPrefix("awdl") { return "AirDrop (\(name))" }
        if name.hasPrefix("llw")  { return "Low‑Latency Wireless (\(name))" }
        if name.hasPrefix("bridge") { return "Bridge (\(name))" }
        if name.hasPrefix("ap")   { return "Personal Hotspot (\(name))" }
        if name.hasPrefix("p2p")  { return "Peer‑to‑Peer (\(name))" }
        return name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if interfaces.isEmpty {
                Text(L.noInterfacesDetected)
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
            Button(L.refreshInterfaces) {
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
        var names: Set<String> = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let flags = Int32(ptr!.pointee.ifa_flags)
                if (flags & (IFF_UP|IFF_RUNNING) == (IFF_UP|IFF_RUNNING)) && (flags & IFF_LOOPBACK == 0) {
                    if let c = ptr!.pointee.ifa_name {
                        let name = String(cString: c)
                        // Show interfaces that SC knows about (Wi-Fi, Ethernet, Thunderbolt, etc.)
                        // or fall back to any "en*" interface
                        if scDisplayNames[name] != nil || name.hasPrefix("en") {
                            names.insert(name)
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return Array(names).sorted()
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

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem!
    var monitor: BandwidthMonitor!
    var timerCancellable: AnyCancellable?
    var detailsPopover: NSPopover?
    var aboutWindowController: NSWindowController?
    var tipWindowController: NSWindowController?
    var settingsWindowController: NSWindowController?
    var onboardingWindowController: NSWindowController?

    var solidHeaderMenuItem: NSMenuItem?
    var solidFooterMenuItem: NSMenuItem?
    
    var themeCancellable: AnyCancellable?

    let tipJarManager = TipJarManager()
    
    /// Returns the NSAppearance matching the current theme.
    /// Solid → .aqua, Dark → .darkAqua, Translucent → nil (follow system)
    static func resolvedNSAppearance() -> NSAppearance? {
        switch Preferences.shared.theme {
        case .solid:       return NSAppearance(named: .aqua)
        case .dark:        return NSAppearance(named: .darkAqua)
        case .translucent: return nil
        }
    }

    private func applyTheme(to window: NSWindow) {
        window.contentView?.wantsLayer = true
        switch Preferences.shared.theme {
        case .solid:
            window.isOpaque = true
            window.backgroundColor = NSColor.windowBackgroundColor
            window.titlebarAppearsTransparent = false
            window.appearance = NSAppearance(named: .aqua)
        case .dark:
            window.isOpaque = true
            window.backgroundColor = NSColor(white: 0.12, alpha: 1)
            window.titlebarAppearsTransparent = false
            window.appearance = NSAppearance(named: .darkAqua)
        case .translucent:
            window.isOpaque = false
            window.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.001)
            window.titlebarAppearsTransparent = true
            window.appearance = nil
        }
    }

    private func applyTheme(to popover: NSPopover) {
        switch Preferences.shared.theme {
        case .solid:       popover.appearance = NSAppearance(named: .aqua)
        case .dark:        popover.appearance = NSAppearance(named: .darkAqua)
        case .translucent: popover.appearance = nil
        }
    }
    
    private func configureMenuHeader(for menu: NSMenu) {
        // Remove existing header if present
        if let header = solidHeaderMenuItem {
            let idx = menu.index(of: header)
            if idx != -1 { menu.removeItem(at: idx) }
            solidHeaderMenuItem = nil
        }

        // Only add a solid header in Solid theme
        guard Preferences.shared.theme == .solid else { return }

        let headerView = NSView(frame: NSRect(x: 0, y: 0, width: 10, height: 8))
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let item = NSMenuItem()
        item.view = headerView
        // Insert at top
        menu.insertItem(item, at: 0)
        solidHeaderMenuItem = item
    }
    
    private func prepareMenuForDisplay(_ menu: NSMenu) {
        // Remove previous header/footer if present
        if let header = solidHeaderMenuItem {
            let idx = menu.index(of: header)
            if idx != -1 { menu.removeItem(at: idx) }
            solidHeaderMenuItem = nil
        }
        if let footer = solidFooterMenuItem {
            let idx = menu.index(of: footer)
            if idx != -1 { menu.removeItem(at: idx) }
            solidFooterMenuItem = nil
        }

        guard Preferences.shared.theme == .solid else { return }

        // Create an opaque white header and footer to disable vibrancy
        let headerView = NSView(frame: NSRect(x: 0, y: 0, width: 10, height: 8))
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.white.cgColor

        let footerView = NSView(frame: NSRect(x: 0, y: 0, width: 10, height: 8))
        footerView.wantsLayer = true
        footerView.layer?.backgroundColor = NSColor.white.cgColor

        let headerItem = NSMenuItem()
        headerItem.view = headerView
        let footerItem = NSMenuItem()
        footerItem.view = footerView

        // Insert header at top and footer at bottom
        menu.insertItem(headerItem, at: 0)
        menu.addItem(footerItem)

        solidHeaderMenuItem = headerItem
        solidFooterMenuItem = footerItem
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        prepareMenuForDisplay(menu)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "runAsHiddenService") {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }

        NSApp.appearance = AppDelegate.resolvedNSAppearance()

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

        // Apply solid background behind the status item text when using Solid theme
        if let button = statusItem.button {
            button.wantsLayer = true
            if Preferences.shared.theme == .solid {
                // White pill background for solid theme
                button.layer?.backgroundColor = NSColor.white.cgColor
                button.layer?.cornerRadius = 6
                button.layer?.masksToBounds = true
                // Ensure readable tint on white
                button.contentTintColor = NSColor.labelColor
            } else {
                // Clear background for translucent theme
                button.layer?.backgroundColor = NSColor.clear.cgColor
                button.layer?.cornerRadius = 0
                button.contentTintColor = nil
            }
        }

        // Menu: About, Open Statistics, Settings, Tip Jar, separator, Quit
        let menu = NSMenu()
        menu.delegate = self

        let aboutItem = NSMenuItem(title: "About Bandwidth Monitor", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let openStatsItem = NSMenuItem(title: "Open Statistics", action: #selector(openDetails), keyEquivalent: "")
        openStatsItem.target = self
        menu.addItem(openStatsItem)

        let speedTestItem = NSMenuItem(title: "Speed Test", action: nil, keyEquivalent: "")
        let speedTestMenu = NSMenu()
        let fastItem = NSMenuItem(title: "Fast.com", action: #selector(openFastCom), keyEquivalent: "")
        fastItem.target = self
        let speedtestItem = NSMenuItem(title: "Speedtest.net", action: #selector(openSpeedtestNet), keyEquivalent: "")
        speedtestItem.target = self
        speedTestMenu.addItem(fastItem)
        speedTestMenu.addItem(speedtestItem)
        speedTestItem.submenu = speedTestMenu
        menu.addItem(speedTestItem)

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let tipJarItem = NSMenuItem(title: "Tip Jar…", action: #selector(showTipJar), keyEquivalent: "")
        tipJarItem.target = self
        menu.addItem(tipJarItem)

        menu.addItem(NSMenuItem.separator())
        
        // Removed call to configureMenuHeader(for: menu)

        let quitItem = NSMenuItem(title: "Quit Bandwidth Monitor", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.appearance = AppDelegate.resolvedNSAppearance()

        statusItem.menu = menu

        statusItem.button?.appearance = AppDelegate.resolvedNSAppearance()

        monitor = BandwidthMonitor()

        // Update UI every 1 second
        timerCancellable = monitor.$rates
            .receive(on: RunLoop.main)
            .sink { [weak self] (rates: BandwidthRates) in
                guard let self = self else { return }
                let title = "↓ \(rates.download) ↑ \(rates.upload)"
                let isSolid = (Preferences.shared.theme == .solid)

                // Build attributed string with green download and red upload
                let fullString = NSMutableAttributedString(string: title)
                let fullRange = NSRange(location: 0, length: fullString.length)

                // Use a darker green for download text
                // let darkGreen = NSColor(calibratedRed: 0.0, green: 0.45, blue: 0.0, alpha: 1.0)

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
                    let downloadColor: NSColor = isSolid ? NSColor(calibratedRed: 0.0, green: 0.45, blue: 0.0, alpha: 1.0) : NSColor.systemGreen
                    fullString.addAttribute(.foregroundColor, value: downloadColor, range: nsDownloadRange)
                    // Bold the numeric portion of the download string
                    boldNumbers(in: fullString, title: title, range: nsDownloadRange)
                }

                // Find range of upload part: "↑ \(rates.upload)"
                let uploadString = "↑ \(rates.upload)"
                if let uploadRange = title.range(of: uploadString) {
                    let nsUploadRange = NSRange(uploadRange, in: title)
                    let uploadColor: NSColor = NSColor.systemRed
                    fullString.addAttribute(.foregroundColor, value: uploadColor, range: nsUploadRange)
                    // Bold the numeric portion of the upload string
                    boldNumbers(in: fullString, title: title, range: nsUploadRange)
                }

                // Set the attributed string to statusItem.button
                self.statusItem.button?.attributedTitle = fullString
                // self.statusItem.button?.title = title // old line commented out
                self.statusItem.button?.appearance = AppDelegate.resolvedNSAppearance()

                // Build richer tooltip showing 24h totals, cycle usage, and peaks
                let t24 = self.monitor.totalsLast24Hours
                let cycle = self.monitor.totalsCurrentCycle
                var tip = "Last 24 h:   ↓ \(BandwidthMonitor.formatTotal(bytes: t24.download))  ↑ \(BandwidthMonitor.formatTotal(bytes: t24.upload))"
                tip += "\nThis cycle:  ↓ \(BandwidthMonitor.formatTotal(bytes: cycle.download))  ↑ \(BandwidthMonitor.formatTotal(bytes: cycle.upload))"
                if Preferences.shared.dataCapEnabled {
                    let capBytes = UInt64(Preferences.shared.dataCapGB * 1_000_000_000)
                    let used = cycle.download + cycle.upload
                    let pct = capBytes > 0 ? Int((Double(used) / Double(capBytes)) * 100) : 0
                    tip += "  (\(pct)% of \(Int(Preferences.shared.dataCapGB)) GB cap)"
                }
                tip += "\nPeak:        ↓ \(BandwidthMonitor.format(bytes: UInt64(self.monitor.peakDownPerSecondBytes), over: 1.0))  ↑ \(BandwidthMonitor.format(bytes: UInt64(self.monitor.peakUpPerSecondBytes), over: 1.0))"
                self.statusItem.button?.toolTip = tip
            }

        monitor.start()

        // Set delegate so notifications display even when the app is active (e.g. Settings window open)
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        // Show onboarding on first launch or when a major version bump requires it
        let currentOnboardingVersion = 1
        if UserDefaults.standard.integer(forKey: "completedOnboardingVersion") < currentOnboardingVersion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showOnboarding()
            }
        }

        themeCancellable = Preferences.shared.$theme
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                NSApp.appearance = AppDelegate.resolvedNSAppearance()
                let resolved = AppDelegate.resolvedNSAppearance()

                if let menu = self.statusItem.menu {
                    menu.appearance = resolved
                    self.prepareMenuForDisplay(menu)
                }
                self.statusItem.button?.appearance = resolved

                if let w = self.aboutWindowController?.window {
                    self.applyTheme(to: w)
                    self.aboutWindowController?.contentViewController?.view.appearance = resolved
                }
                if let w = self.tipWindowController?.window {
                    self.applyTheme(to: w)
                    self.tipWindowController?.contentViewController?.view.appearance = resolved
                }
                if let w = self.settingsWindowController?.window {
                    self.applyTheme(to: w)
                    self.settingsWindowController?.contentViewController?.view.appearance = resolved
                }
                if let p = self.detailsPopover {
                    self.applyTheme(to: p)
                }
                // Re-apply solid/clear background for the status item when theme changes
                if let button = self.statusItem.button {
                    button.wantsLayer = true
                    if Preferences.shared.theme == .solid {
                        button.layer?.backgroundColor = NSColor.white.cgColor
                        button.layer?.cornerRadius = 6
                        button.layer?.masksToBounds = true
                        button.contentTintColor = NSColor.labelColor
                    } else {
                        button.layer?.backgroundColor = NSColor.clear.cgColor
                        button.layer?.cornerRadius = 0
                        button.contentTintColor = nil
                    }
                }
            }
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

        hosting.view.appearance = AppDelegate.resolvedNSAppearance()

        applyTheme(to: window)
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

        hosting.view.appearance = AppDelegate.resolvedNSAppearance()

        applyTheme(to: window)
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
        let contentView = SettingsView(forceSolidBackground: true) { [weak self] in
            self?.settingsWindowController?.close()
            self?.settingsWindowController = nil
        }
        let hosting = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Settings"
        window.setContentSize(NSSize(width: 520, height: 420))
        window.contentMinSize = NSSize(width: 420, height: 320)
        window.styleMask.insert([.titled, .closable, .resizable])
        window.isReleasedWhenClosed = false

        hosting.view.appearance = AppDelegate.resolvedNSAppearance()
        applyTheme(to: window)
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
        
        let hostingController = NSHostingController(rootView: BandwidthTotalsView(monitor: monitor))
        hostingController.view.appearance = AppDelegate.resolvedNSAppearance()
        popover.contentViewController = hostingController
        
        applyTheme(to: popover)
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            detailsPopover = popover
        }
    }

    func showOnboarding() {
        let contentView = OnboardingView { [weak self] in
            UserDefaults.standard.set(1, forKey: "completedOnboardingVersion")
            self?.onboardingWindowController?.close()
            self?.onboardingWindowController = nil
        }
        let hosting = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Welcome to Bandwidth Monitor"
        window.setContentSize(NSSize(width: 480, height: 380))
        window.styleMask = [NSWindow.StyleMask.titled, NSWindow.StyleMask.closable]
        window.isReleasedWhenClosed = false
        window.isOpaque = true
        window.backgroundColor = NSColor.windowBackgroundColor
        let controller = NSWindowController(window: window)
        self.onboardingWindowController = controller
        controller.showWindow(self)
        window.center()
    }

    @objc func openFastCom(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "https://fast.com")!)
    }

    @objc func openSpeedtestNet(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "https://www.speedtest.net")!)
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

nonisolated extension HistorySample: Codable {}
nonisolated extension PersistedData: Codable {}

@MainActor final class BandwidthMonitor: ObservableObject {
    @Published var rates = BandwidthRates(download: "0 Mbps", upload: "0 Mbps", timestamp: Date())
    @Published var recentSamples: [(time: Date, down: UInt64, up: UInt64, dt: TimeInterval)] = []
    @Published var peakDownPerSecondBytes: Double = 0
    @Published var peakUpPerSecondBytes: Double = 0
    
    private var timerSource: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "net.bandwidth.monitor.timer", qos: .userInitiated)
    private var prevRx: UInt64 = 0
    private var prevTx: UInt64 = 0
    private var lastInterfaceSet: Set<String> = []
    private var interfaceChangeSuppressCount: Int = 0 // number of upcoming samples to suppress
    private let smoothWindow: Int = 5
    private var recentDownRates: [Double] = [] // bytes/sec per sample
    private var recentUpRates: [Double] = []
    private var isFirstSample = true
    // Store history as array of HistorySample for codable persistence
    private var history: [HistorySample] = []
    
    private var totalDownloadAllTime: UInt64 = 0
    private var totalUploadAllTime: UInt64 = 0
    
    private let prefs = Preferences.shared
    
    private var lastSampleDate: Date?
    private var lastSaveDate: Date = .distantPast
    private var lastWidgetUpdateDate: Date = .distantPast
    // Tracks which data cap thresholds (75, 90, 100) have already fired a notification this cycle
    private var firedCapThresholds: Set<Int> = []
    // The billing cycle start date when thresholds were last reset, used to detect cycle rollover
    private var lastKnownCycleStart: Date = .distantPast
    private var samplingCancellable: AnyCancellable?
    
    // Expose as a property
    var totalsAllTime: (download: UInt64, upload: UInt64) {
        (totalDownloadAllTime, totalUploadAllTime)
    }
        
    // File URL to save/load history JSON data — computed once and cached
    private lazy var historyURL: URL = {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDir = dir.appendingPathComponent("MenuBarBandwidthMonitor", isDirectory: true)
        try? fm.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("history.json")
    }()
    
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
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rescheduleTimerIfNeeded()
            }
    }
    
    func start() {
        stop()
        let interval = max(0.25, prefs.samplingInterval)
        let source = DispatchSource.makeTimerSource(queue: timerQueue)
        // Use strict leeway to reduce jitter
        source.schedule(deadline: .now() + interval, repeating: interval, leeway: .nanoseconds(0))
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.poll()
            }
        }
        timerSource = source
        source.resume()
    }
    
    func stop() {
        timerSource?.cancel()
        timerSource = nil
        saveHistory() // Save the history when stopping monitoring
        // Reset smoothing buffers
        recentDownRates.removeAll(keepingCapacity: true)
        recentUpRates.removeAll(keepingCapacity: true)
    }
    
    private func rescheduleTimerIfNeeded() {
        let interval = max(0.25, prefs.samplingInterval)
        timerSource?.cancel()
        timerSource = nil
        let source = DispatchSource.makeTimerSource(queue: timerQueue)
        source.schedule(deadline: .now() + interval, repeating: interval, leeway: .nanoseconds(0))
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.poll()
            }
        }
        timerSource = source
        source.resume()
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
        let elapsed = max(0.2, now.timeIntervalSince(lastSampleDate ?? now))
        lastSampleDate = now

        // Detect interface set changes and suppress next 2 samples to avoid spikes
        var interfaceSetChanged = false
        if lastInterfaceSet != names {
            interfaceSetChanged = true
            lastInterfaceSet = names
            interfaceChangeSuppressCount = 2
        }
        
        // Handle counter wraparound (interface reset or overflow) and interface set changes
        let rawDeltaRx: UInt64 = rx >= prevRx ? rx &- prevRx : rx
        let rawDeltaTx: UInt64 = tx >= prevTx ? tx &- prevTx : tx
        let suppress = interfaceSetChanged || interfaceChangeSuppressCount > 0
        let deltaRx: UInt64 = suppress ? 0 : rawDeltaRx
        let deltaTx: UInt64 = suppress ? 0 : rawDeltaTx
        if interfaceChangeSuppressCount > 0 { interfaceChangeSuppressCount -= 1 }
        
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
        
        let currentDownPerSecond = Double(deltaRx) / elapsed
        let currentUpPerSecond = Double(deltaTx) / elapsed

        // Update smoothing buffers (moving average over last `smoothWindow` samples)
        recentDownRates.append(currentDownPerSecond)
        recentUpRates.append(currentUpPerSecond)
        if recentDownRates.count > smoothWindow { recentDownRates.removeFirst(recentDownRates.count - smoothWindow) }
        if recentUpRates.count > smoothWindow { recentUpRates.removeFirst(recentUpRates.count - smoothWindow) }
        let avgDown = recentDownRates.isEmpty ? 0 : (recentDownRates.reduce(0, +) / Double(recentDownRates.count))
        let avgUp = recentUpRates.isEmpty ? 0 : (recentUpRates.reduce(0, +) / Double(recentUpRates.count))

        // Publish updates (MainActor enforced by class annotation)
        // Update recentSamples (published)
        self.recentSamples.append((time: now, down: deltaRx, up: deltaTx, dt: elapsed))
        let cutoffRecent = now.addingTimeInterval(-300)
        self.recentSamples.removeAll { $0.time < cutoffRecent }

        // Update peaks (published)
        if avgDown > self.peakDownPerSecondBytes { self.peakDownPerSecondBytes = avgDown }
        if avgUp > self.peakUpPerSecondBytes { self.peakUpPerSecondBytes = avgUp }

        // Update rates (published)
        self.rates = BandwidthRates(
            download: BandwidthMonitor.format(bytes: UInt64(avgDown), over: 1.0),
            upload: BandwidthMonitor.format(bytes: UInt64(avgUp), over: 1.0),
            timestamp: now
        )

        // Check data cap thresholds and fire notifications if needed
        checkDataCapNotifications()

        // Write summary data to shared App Group store for the widget (throttled to ~60s)
        if now.timeIntervalSince(lastWidgetUpdateDate) >= 60 {
            updateWidgetSharedData()
            lastWidgetUpdateDate = now
        }
    }

    private func updateWidgetSharedData() {
        guard let defaults = UserDefaults(suiteName: "group.com.bandwidth-monitor.shared") else { return }
        let t24 = totalsLast24Hours
        let cycle = totalsCurrentCycle
        let prefs = Preferences.shared
        // UserDefaults doesn't support UInt64 — store as Double (safe up to ~9 PB)
        defaults.set(Double(t24.download), forKey: "widget_24h_down")
        defaults.set(Double(t24.upload), forKey: "widget_24h_up")
        defaults.set(Double(cycle.download), forKey: "widget_cycle_down")
        defaults.set(Double(cycle.upload), forKey: "widget_cycle_up")
        defaults.set(peakDownPerSecondBytes, forKey: "widget_peak_down")
        defaults.set(peakUpPerSecondBytes, forKey: "widget_peak_up")
        defaults.set(prefs.dataCapEnabled, forKey: "widget_cap_enabled")
        defaults.set(prefs.dataCapGB, forKey: "widget_cap_gb")
        // Store Date as TimeInterval so it round-trips safely
        defaults.set(Date().timeIntervalSince1970, forKey: "widget_last_updated")
        WidgetCenter.shared.reloadTimelines(ofKind: "BandwidthWidget")
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
        // Capture URL on the main actor to avoid crossing actor boundaries in the background closure
        let url = self.historyURL

        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: url, options: .atomic)
            } catch {
                // ignore errors
            }
        }
    }
    
    // Load history array from JSON file on disk, filtering out old samples
    private func loadHistory() {
        let cutoff = Date().addingTimeInterval(-35 * 86400)
        do {
            let data = try Data(contentsOf: historyURL)
            // Try the current format first; fall back to the legacy format (array only)
            do {
                let object = try JSONDecoder().decode(PersistedData.self, from: data)
                self.history = object.history.filter { $0.timestamp >= cutoff }
                self.totalDownloadAllTime = object.totalDownloadAllTime
                self.totalUploadAllTime = object.totalUploadAllTime
            } catch {
                let old = try JSONDecoder().decode([HistorySample].self, from: data)
                self.history = old.filter { $0.timestamp >= cutoff }
                self.totalDownloadAllTime = 0
                self.totalUploadAllTime = 0
            }
        } catch {
            self.history = []
            self.totalDownloadAllTime = 0
            self.totalUploadAllTime = 0
        }
    }
    
    func resetTotals() {
        self.history = []
        self.totalDownloadAllTime = 0
        self.totalUploadAllTime = 0
        self.prevRx = 0
        self.prevTx = 0
        self.isFirstSample = true
        self.peakDownPerSecondBytes = 0
        self.peakUpPerSecondBytes = 0
        self.firedCapThresholds.removeAll()
        self.lastKnownCycleStart = .distantPast
        self.saveHistory()
        self.rates = BandwidthRates(download: "0 Mbps", upload: "0 Mbps", timestamp: Date())
    }
    
    private func currentCycleStart(now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let prefs = Preferences.shared
        let billingDay = max(1, min(31, prefs.billingDay))

        // Clamps billingDay to the last valid day of a given month
        func clampedDate(year: Int, month: Int) -> Date? {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            // Find the last day of the target month then take the minimum
            if let firstOfMonth = calendar.date(from: comps),
               let range = calendar.range(of: .day, in: .month, for: firstOfMonth) {
                comps.day = min(billingDay, range.upperBound - 1)
                return calendar.date(from: comps)
            }
            return nil
        }

        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return calendar.startOfDay(for: now)
        }

        // Determine the billing day clamped to this month
        let firstOfThisMonth = calendar.date(from: DateComponents(year: year, month: month))!
        let daysInThisMonth = calendar.range(of: .day, in: .month, for: firstOfThisMonth)!.upperBound - 1
        let effectiveBillingDayThisMonth = min(billingDay, daysInThisMonth)

        if day < effectiveBillingDayThisMonth {
            // Cycle started last month
            let prevMonth = month == 1 ? 12 : month - 1
            let prevYear  = month == 1 ? year - 1 : year
            return clampedDate(year: prevYear, month: prevMonth) ?? calendar.startOfDay(for: now)
        } else {
            // Cycle started this month
            return clampedDate(year: year, month: month) ?? calendar.startOfDay(for: now)
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

    // Checks current cycle usage against 75%, 90%, and 100% thresholds and fires
    // a local notification the first time each threshold is crossed per billing cycle.
    private func checkDataCapNotifications() {
        let prefs = Preferences.shared
        guard prefs.dataCapEnabled else { return }

        let cycleStart = currentCycleStart()

        // If the billing cycle has rolled over, reset fired thresholds for the new cycle
        if cycleStart > lastKnownCycleStart {
            firedCapThresholds.removeAll()
            lastKnownCycleStart = cycleStart
        }

        let capBytes = UInt64(prefs.dataCapGB * 1_000_000_000)
        guard capBytes > 0 else { return }

        let cycle = totalsCurrentCycle
        let usedBytes = cycle.download &+ cycle.upload
        let percent = Int(Double(usedBytes) / Double(capBytes) * 100)

        let thresholds: [Int] = [75, 90, 100]
        let gb = Int(prefs.dataCapGB)

        for threshold in thresholds {
            guard percent >= threshold, !firedCapThresholds.contains(threshold) else { continue }
            firedCapThresholds.insert(threshold)
            sendNotification(
                identifier: "datacap.\(threshold)",
                title: L.capTitle(pct: threshold),
                body: L.capBody(pct: threshold, gb: gb)
            )
        }
    }

    private func sendNotification(identifier: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { _ in }
    }
}

struct BandwidthTotalsView: View {
    @ObservedObject var monitor: BandwidthMonitor
    @State private var showResetAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L.totalData)
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
                    Text(L.download)
                        .font(.headline)
                    Text(BandwidthMonitor.formatTotal(bytes: monitor.totalsAllTime.download))
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.green)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text(L.upload)
                        .font(.headline)
                    Text(BandwidthMonitor.formatTotal(bytes: monitor.totalsAllTime.upload))
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L.peakRates).font(.headline)
                HStack {
                    Text(L.down)
                    Text(BandwidthMonitor.format(bytes: UInt64(monitor.peakDownPerSecondBytes), over: 1.0))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.green)
                    Spacer()
                    Text(L.up)
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
                    Text(L.currentCycleUsage).font(.headline)
                    Text("\(L.usedRemaining): \(BandwidthMonitor.formatTotal(bytes: usedBytes))  •  \(L.remaining): \(BandwidthMonitor.formatTotal(bytes: remaining))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Text(L.resetTotals)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 16)
            .buttonStyle(.borderedProminent)
            .alert(L.resetAlertTitle, isPresented: $showResetAlert) {
                Button(L.resetConfirm, role: .destructive) {
                    monitor.resetTotals()
                }
                Button(L.cancel, role: .cancel) {}
            } message: {
                Text(L.resetAlertMessage)
            }
            
            Spacer()
        }
        .frame(width: 320)
        .padding(18)
        .themedBackground()
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

