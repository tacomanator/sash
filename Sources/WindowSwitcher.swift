import AppKit
import ApplicationServices

enum CycleDirection {
    case forward
    case reverse
}

final class WindowSwitcher {
    static let shared = WindowSwitcher()

    func cycleWindows(direction: CycleDirection = .forward) {
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
        switch direction {
        case .forward:
            // Raise every window behind the frontmost from back to front.
            // This rotates the stack: [A,B,C] → [B,C,A], [B,C,A] → [C,A,B], etc.
            for i in stride(from: visibleWindows.count - 1, through: 1, by: -1) {
                AXUIElementPerformAction(visibleWindows[i], kAXRaiseAction as CFString)
            }
            AXUIElementSetAttributeValue(
                visibleWindows[1],
                kAXMainAttribute as CFString,
                kCFBooleanTrue
            )
        case .reverse:
            // Raise only the backmost window to front.
            // This rotates the opposite direction: [A,B,C] → [C,A,B].
            AXUIElementPerformAction(visibleWindows.last!, kAXRaiseAction as CFString)
            AXUIElementSetAttributeValue(
                visibleWindows.last!,
                kAXMainAttribute as CFString,
                kCFBooleanTrue
            )
        }
    }
}
