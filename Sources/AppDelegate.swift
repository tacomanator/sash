import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !AccessibilityHelper.checkPermission() {
            AccessibilityHelper.requestPermission()
        }

        // Register saved (or default) forward hotkey
        HotkeyManager.shared.register(
            Hotkey.load(for: .forward) ?? Hotkey.defaultHotkey
        )

        // Register reverse hotkey if configured
        if let reverse = Hotkey.load(for: .reverse) {
            HotkeyManager.shared.register(reverse, for: .reverse)
        }
    }
}
