import SwiftUI

@main
struct AppsQuitterApp: App {
    @State private var settings = SettingsStore.shared

    var body: some Scene {
        MenuBarExtra("AppsQuitter", systemImage: "xmark.app") {
            MenuContent()
                .environment(settings)
        }

        Settings {
            SettingsView()
                .environment(settings)
        }
    }
}

private struct MenuContent: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Quit All Apps") {
            settings.quitAllApps()
        }
        .keyboardShortcut(settings.shortcut.keyboardShortcut)

        Divider()

        Button("Settings…") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",")

        Button("Quit AppsQuitter") {
            NSApp.terminate(nil)
        }
    }
}
