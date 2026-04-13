import Carbon
import AppKit

final class HotkeyManager {
    static let shared = HotkeyManager()

    private var forwardHotKeyRef: EventHotKeyRef?
    private var reverseHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private init() {
        installHandler()
    }

    private func installHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                guard let event = event else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr else { return OSStatus(eventNotHandledErr) }

                let direction: CycleDirection = hotKeyID.id == 2 ? .reverse : .forward
                DispatchQueue.main.async {
                    WindowSwitcher.shared.cycleWindows(direction: direction)
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
    }

    func register(_ hotkey: Hotkey, for direction: CycleDirection = .forward) {
        unregister(direction)

        let id: UInt32 = direction == .forward ? 1 : 2
        let hotKeyID = EventHotKeyID(signature: OSType(0x5357_4348), id: id) // "SWCH"

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if status != noErr {
            print("[Sash] Failed to register hotkey: \(status)")
        } else {
            switch direction {
            case .forward: forwardHotKeyRef = ref
            case .reverse: reverseHotKeyRef = ref
            }
        }
    }

    func unregister(_ direction: CycleDirection = .forward) {
        switch direction {
        case .forward:
            if let ref = forwardHotKeyRef {
                UnregisterEventHotKey(ref)
                forwardHotKeyRef = nil
            }
        case .reverse:
            if let ref = reverseHotKeyRef {
                UnregisterEventHotKey(ref)
                reverseHotKeyRef = nil
            }
        }
    }
}
