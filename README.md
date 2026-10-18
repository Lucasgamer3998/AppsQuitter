# AppsQuitter

A small macOS menu-bar app that quits all your running apps with one keyboard shortcut. Press **⌃⌥⌘Q** (Control + Option + Command + Q) anywhere and every open app is closed.

- Apps are asked to quit normally, as if you pressed ⌘Q in each one, so apps with unsaved work still ask you to save first. Finder and AppsQuitter itself are never quit.
- In Settings you can change the shortcut, choose apps that should always stay open, and turn on "Launch at login". The app lives in the menu bar and has no Dock icon.
- The shortcut works system-wide without Accessibility permission. If another app already uses the combination you pick, Settings shows a warning.

## Build

1. Open `AppsQuitter.xcodeproj` in Xcode (macOS 27 SDK; the app runs on macOS 14 or later).
2. For the AppsQuitter target, go to Signing & Capabilities and pick your Team.
3. Change the bundle identifier from `dk.xtrror.appsquitter.app` to your own.
4. Run. AppsQuitter appears in the menu bar; open Settings from its menu to change the shortcut or the list of apps to keep open.

The App Sandbox is turned off, because sandboxed apps aren't allowed to quit other apps. That also means the app can't be distributed through the Mac App Store as it is.

## Files

- `AppsQuitter/`: the whole app
  - `AppsQuitterApp.swift`: app entry point, menu-bar menu and Settings window
  - `AppQuitter.swift`: finds running apps and asks them to quit
  - `HotKey.swift`: registers the system-wide shortcut
  - `Shortcut.swift`: the shortcut model and the recorder button in Settings
  - `SettingsStore.swift`: saved settings and launch at login
  - `SettingsView.swift`: the Settings window

## License

PolyForm Noncommercial 1.0.0: free to use, change and share for any noncommercial purpose. Commercial use is not allowed. See [LICENSE.md](LICENSE.md) for the full terms.
