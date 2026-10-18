import Carbon.HIToolbox

/// A system-wide keyboard shortcut using the Carbon hot key API.
/// Works without Accessibility permissions.
final class HotKey {
    private static var handlers: [UInt32: () -> Void] = [:]
    private static var eventHandlerInstalled = false
    private static var nextID: UInt32 = 1

    private var hotKeyRef: EventHotKeyRef?
    private let id: UInt32

    /// Returns nil if the combination can't be registered (e.g. another app already owns it).
    init?(_ shortcut: Shortcut, action: @escaping () -> Void) {
        id = Self.nextID
        Self.nextID += 1
        Self.installEventHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: OSType(0x4150_5154) /* 'APQT' */, id: id)
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, hotKeyID,
                                         GetApplicationEventTarget(), 0, &hotKeyRef)
        guard status == noErr else { return nil }
        Self.handlers[id] = action
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        Self.handlers[id] = nil
    }

    private static func installEventHandlerIfNeeded() {
        guard !eventHandlerInstalled else { return }
        eventHandlerInstalled = true

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hotKeyID)
            // Carbon delivers application-target events on the main thread.
            MainActor.assumeIsolated {
                HotKey.handlers[hotKeyID.id]?()
            }
            return noErr
        }, 1, &eventType, nil, nil)
    }
}
