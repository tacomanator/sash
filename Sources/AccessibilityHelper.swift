import AppKit
import ApplicationServices

enum AccessibilityHelper {
    static func checkPermission() -> Bool {
        AXIsProcessTrusted()
    }

    static func requestPermission() {
        // Clear any stale TCC entry (e.g. from a previous build with a different
        // ad-hoc signature) so the system prompt appears cleanly.
        let bundleID = Bundle.main.bundleIdentifier ?? "com.sash.app"
        let task = Process()
        task.launchPath = "/usr/bin/tccutil"
        task.arguments = ["reset", "Accessibility", bundleID]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        try? task.run()
        task.waitUntilExit()

        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [trusted: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        )
    }
}
