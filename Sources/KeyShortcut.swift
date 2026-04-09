import AppKit
import Carbon.HIToolbox

struct KeyShortcut: Codable, Equatable {
    let keyCode: UInt32
    let modifierRawValue: UInt

    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = UInt32(keyCode)
        self.modifierRawValue = modifiers.intersection(.deviceIndependentFlagsMask).rawValue
    }



    private var cocoaModifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierRawValue)
    }

    var carbonModifiers: UInt32 {
        var carbon: UInt32 = 0
        let mods = cocoaModifiers
        if mods.contains(.command) { carbon |= UInt32(cmdKey) }
        if mods.contains(.shift) { carbon |= UInt32(shiftKey) }
        if mods.contains(.option) { carbon |= UInt32(optionKey) }
        if mods.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }

    var displayString: String {
        var result = ""
        let mods = cocoaModifiers
        if mods.contains(.control) { result += "⌃" }
        if mods.contains(.option) { result += "⌥" }
        if mods.contains(.shift) { result += "⇧" }
        if mods.contains(.command) { result += "⌘" }
        result += keyName
        return result
    }

    private var keyName: String {
        // Special keys always use their symbol regardless of layout
        if let special = specialKeyName { return special }
        // Use the current keyboard layout to resolve the character
        if let translated = translatedKeyName { return translated }
        return String(format: "Key(%d)", keyCode)
    }

    private var specialKeyName: String? {
        switch Int(keyCode) {
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Space"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Escape: return "⎋"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default: return nil
        }
    }

    /// Resolve the key name from the current keyboard input source via UCKeyTranslate.
    private var translatedKeyName: String? {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let layoutDataPtr = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }

        let layoutData = unsafeBitCast(layoutDataPtr, to: CFData.self)
        let keyboardLayout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)

        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0

        let status = UCKeyTranslate(
            keyboardLayout,
            UInt16(keyCode),
            UInt16(kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            UInt32(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            chars.count,
            &length,
            &chars
        )

        guard status == noErr, length > 0 else { return nil }
        let str = String(utf16CodeUnits: chars, count: length)
        guard !str.isEmpty, !str.allSatisfy({ $0.isWhitespace }) else { return nil }
        return str.uppercased()
    }

    // MARK: - Persistence

    private static let defaultsKey = "savedShortcut"

    // Cmd+Shift+2 (@)
    static let defaultShortcut = KeyShortcut(
        keyCode: UInt16(kVK_ANSI_2),
        modifiers: [.command, .shift]
    )

    static func load() -> KeyShortcut {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let shortcut = try? JSONDecoder().decode(KeyShortcut.self, from: data)
        else { return defaultShortcut }
        return shortcut
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
