import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var selection: Set<String> = []

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)

                LabeledContent("Quit all apps shortcut") {
                    HStack {
                        ShortcutRecorder()
                        Button("Reset") { settings.shortcut = .default }
                            .disabled(settings.shortcut == .default)
                    }
                }
            } footer: {
                if settings.shortcutUnavailable {
                    Text("\(settings.shortcut.displayString) is already used by another app. Choose a different shortcut.")
                        .foregroundStyle(.red)
                } else {
                    Text("Press \(settings.shortcut.displayString) anywhere to quit all running apps.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Apps to keep open") {
                List(selection: $selection) {
                    ForEach(sortedExcluded, id: \.self) { bundleID in
                        AppRow(bundleID: bundleID)
                    }
                }
                .frame(minHeight: 200)
                .overlay {
                    if settings.excludedBundleIDs.isEmpty {
                        Text("No apps excluded — every app will be quit.")
                            .foregroundStyle(.secondary)
                    }
                }
                .onDeleteCommand(perform: removeSelected)

                HStack {
                    Menu("Add Running App") {
                        ForEach(runningApps, id: \.bundleID) { app in
                            Button(app.name) {
                                settings.excludedBundleIDs.insert(app.bundleID)
                            }
                        }
                    }
                    .fixedSize()

                    Button("Choose App…", action: chooseApp)

                    Spacer()

                    Button("Remove", action: removeSelected)
                        .disabled(selection.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 460)
    }

    private var sortedExcluded: [String] {
        settings.excludedBundleIDs.sorted {
            AppInfo.name(for: $0).localizedCaseInsensitiveCompare(AppInfo.name(for: $1)) == .orderedAscending
        }
    }

    private var runningApps: [(bundleID: String, name: String)] {
        let ownID = Bundle.main.bundleIdentifier
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> (String, String)? in
                guard let id = app.bundleIdentifier, id != ownID,
                      !AppQuitter.alwaysKept.contains(id),
                      !settings.excludedBundleIDs.contains(id) else { return nil }
                return (id, app.localizedName ?? id)
            }
            .sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
    }

    private func removeSelected() {
        settings.excludedBundleIDs.subtract(selection)
        selection.removeAll()
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK else { return }

        for url in panel.urls {
            if let id = Bundle(url: url)?.bundleIdentifier {
                settings.excludedBundleIDs.insert(id)
            }
        }
    }
}

private struct AppRow: View {
    let bundleID: String

    var body: some View {
        HStack {
            Image(nsImage: AppInfo.icon(for: bundleID))
                .resizable()
                .frame(width: 20, height: 20)
            Text(AppInfo.name(for: bundleID))
        }
    }
}

private enum AppInfo {
    static func url(for bundleID: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    static func name(for bundleID: String) -> String {
        guard let url = url(for: bundleID) else { return bundleID }
        return FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")
    }

    static func icon(for bundleID: String) -> NSImage {
        guard let url = url(for: bundleID) else {
            return NSWorkspace.shared.icon(for: .application)
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
