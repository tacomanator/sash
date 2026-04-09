import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !AccessibilityHelper.checkPermission() {
            AccessibilityHelper.requestPermission()
        }

        // Register saved (or default) shortcut
        HotkeyManager.shared.register(KeyShortcut.load())
    }
}
