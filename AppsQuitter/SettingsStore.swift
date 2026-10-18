import Foundation
import Observation
import ServiceManagement

@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    private static let excludedKey = "excludedBundleIDs"
    private static let shortcutKey = "shortcut"

    var excludedBundleIDs: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(excludedBundleIDs).sorted(), forKey: Self.excludedKey)
        }
    }

    var shortcut: Shortcut {
        didSet {
            UserDefaults.standard.set(try? JSONEncoder().encode(shortcut), forKey: Self.shortcutKey)
            updateHotKey()
        }
    }

    /// True while the settings window is recording a new shortcut; the global one is paused.
    var isRecordingShortcut = false {
        didSet { updateHotKey() }
    }

    /// Set when the current shortcut couldn't be registered.
    private(set) var shortcutUnavailable = false

    @ObservationIgnored private var hotKey: HotKey?

    /// Mirrors the system's login item state for this app.
    var launchAtLogin: Bool {
        get {
            access(keyPath: \.launchAtLogin)
            return SMAppService.mainApp.status == .enabled
        }
        set {
            withMutation(keyPath: \.launchAtLogin) {
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    NSLog("AppsQuitter: failed to update login item: \(error)")
                }
            }
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        excludedBundleIDs = Set(defaults.stringArray(forKey: Self.excludedKey) ?? [])
        shortcut = defaults.data(forKey: Self.shortcutKey)
            .flatMap { try? JSONDecoder().decode(Shortcut.self, from: $0) }
            ?? .default
        updateHotKey()
    }

    func quitAllApps() {
        AppQuitter.quitAll(excluding: excludedBundleIDs)
    }

    private func updateHotKey() {
        hotKey = nil
        guard !isRecordingShortcut else { return }
        hotKey = HotKey(shortcut) { [weak self] in self?.quitAllApps() }
        shortcutUnavailable = hotKey == nil
    }
}
