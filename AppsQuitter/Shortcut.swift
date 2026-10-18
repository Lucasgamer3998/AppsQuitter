import AppKit
import Carbon.HIToolbox
import SwiftUI

/// A key combination, stored in the Carbon format the hot key API expects.
struct Shortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    /// Display label for the key itself, e.g. "Q" or "F5".
    var key: String

    static let `default` = Shortcut(keyCode: UInt32(kVK_ANSI_Q),
                                    modifiers: UInt32(controlKey | optionKey | cmdKey),
                                    key: "Q")

    /// e.g. "⌃⌥⌘Q"
    var displayString: String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { s += "⌘" }
        return s + key
    }

    /// The same combination for SwiftUI menu items, when the key is a plain character.
    var keyboardShortcut: KeyboardShortcut? {
        guard key.count == 1, let char = key.lowercased().first else { return nil }
        var mods: SwiftUI.EventModifiers = []
        if modifiers & UInt32(controlKey) != 0 { mods.insert(.control) }
        if modifiers & UInt32(optionKey) != 0 { mods.insert(.option) }
        if modifiers & UInt32(shiftKey) != 0 { mods.insert(.shift) }
        if modifiers & UInt32(cmdKey) != 0 { mods.insert(.command) }
        return KeyboardShortcut(KeyEquivalent(char), modifiers: mods)
    }

    /// Builds a shortcut from a key press. Returns nil unless ⌘, ⌥ or ⌃ is held,
    /// so a plain key press can't become a global shortcut.
    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard !flags.intersection([.command, .option, .control]).isEmpty else { return nil }

        var mods: UInt32 = 0
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        if flags.contains(.command) { mods |= UInt32(cmdKey) }

        let code = Int(event.keyCode)
        let label = Self.specialKeyNames[code]
            ?? event.charactersIgnoringModifiers?.uppercased()
            ?? "?"
        self.init(keyCode: UInt32(code), modifiers: mods, key: label)
    }

    init(keyCode: UInt32, modifiers: UInt32, key: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.key = key
    }

    private static let specialKeyNames: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫",
        kVK_ForwardDelete: "⌦", kVK_Escape: "⎋", kVK_Home: "↖", kVK_End: "↘",
        kVK_PageUp: "⇞", kVK_PageDown: "⇟",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5",
        kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10",
        kVK_F11: "F11", kVK_F12: "F12",
    ]
}

/// A button that records a new shortcut when clicked. Esc cancels.
struct ShortcutRecorder: View {
    @Environment(SettingsStore.self) private var settings
    @State private var monitor: Any?

    var body: some View {
        Button {
            monitor == nil ? startRecording() : stopRecording()
        } label: {
            Text(monitor == nil ? settings.shortcut.displayString : "Type shortcut…")
                .frame(minWidth: 110)
        }
        .onDisappear(perform: stopRecording)
    }

    private func startRecording() {
        // Pause the global shortcut so pressing it is recorded instead of quitting apps.
        settings.isRecordingShortcut = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
            } else if let shortcut = Shortcut(event: event) {
                settings.shortcut = shortcut
                stopRecording()
            } else {
                NSSound.beep()
            }
            return nil
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        settings.isRecordingShortcut = false
    }
}
