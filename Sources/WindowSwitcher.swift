import AppKit
import ApplicationServices

final class WindowSwitcher {
    static let shared = WindowSwitcher()

    func cycleWindows() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }

        // Don't cycle our own windows
        guard frontApp.bundleIdentifier != Bundle.main.bundleIdentifier else { return }

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        // Get all windows for the frontmost app
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsRef
        )
        guard result == .success,
              let windows = windowsRef as? [AXUIElement]
        else { return }

        // Filter to non-minimized windows
        let visibleWindows = windows.filter { window in
            var minimizedRef: CFTypeRef?
            let res = AXUIElementCopyAttributeValue(
                window,
                kAXMinimizedAttribute as CFString,
                &minimizedRef
            )
            if res == .success, let minimized = minimizedRef as? Bool {
                return !minimized
            }
            return true
        }

        guard visibleWindows.count > 1 else { return }

        // The AX windows list is ordered front-to-back.
        // To cycle all windows (not just swap the top two), raise every
        // window behind the frontmost from back to front. This rotates
        // the entire stack: [A,B,C] → [B,C,A], [B,C,A] → [C,A,B], etc.
        for i in stride(from: visibleWindows.count - 1, through: 1, by: -1) {
            AXUIElementPerformAction(visibleWindows[i], kAXRaiseAction as CFString)
        }
        AXUIElementSetAttributeValue(
            visibleWindows[1],
            kAXMainAttribute as CFString,
            kCFBooleanTrue
        )
    }
}
