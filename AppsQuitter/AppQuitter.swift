import AppKit

enum AppQuitter {
    /// Apps that are never quit, regardless of user settings.
    static let alwaysKept: Set<String> = [
        "com.apple.finder",
    ]

    /// Asks every regular (Dock-visible) app to quit, except the excluded ones.
    /// Apps with unsaved changes will still show their own "Save?" prompt.
    static func quitAll(excluding excluded: Set<String>) {
        let ownPID = ProcessInfo.processInfo.processIdentifier

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  app.processIdentifier != ownPID,
                  let bundleID = app.bundleIdentifier,
                  !alwaysKept.contains(bundleID),
                  !excluded.contains(bundleID)
            else { continue }

            app.terminate()
        }
    }
}
