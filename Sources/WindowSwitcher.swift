import AppKit
import ApplicationServices

/// Get the CGWindowID backing an AXUIElement window.
@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement, _ outWID: UnsafeMutablePointer<CGWindowID>) -> AXError

enum CycleDirection {
    case forward
    case reverse
}

final class WindowSwitcher {
    static let shared = WindowSwitcher()

    /// Stable rotation order by CGWindowID, independent of current z-order.
    private var rotationOrder: [CGWindowID] = []
    private var rotationPID: pid_t = 0

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

        cycleWithRotation(visibleWindows: visibleWindows, pid: frontApp.processIdentifier, direction: direction)
    }

    /// Raises the next (or previous) window in a stable rotation order.
    /// The rotation list is maintained independently of z-order so that
    /// every window is visited exactly once per cycle.
    private func cycleWithRotation(visibleWindows: [AXUIElement], pid: pid_t, direction: CycleDirection) {
        // Map each visible window to its CGWindowID
        var idToElement: [CGWindowID: AXUIElement] = [:]
        var windowIDs: [CGWindowID] = []
        for w in visibleWindows {
            var wid: CGWindowID = 0
            if _AXUIElementGetWindow(w, &wid) == .success {
                idToElement[wid] = w
                windowIDs.append(wid)
            }
        }
        guard windowIDs.count > 1 else { return }

        // Reset rotation when switching apps or when it's stale
        let currentSet = Set(windowIDs)
        if pid != rotationPID {
            rotationOrder = windowIDs
            rotationPID = pid
        } else {
            // Remove closed windows
            rotationOrder = rotationOrder.filter { currentSet.contains($0) }
            // Append any newly opened windows
            for wid in windowIDs where !rotationOrder.contains(wid) {
                rotationOrder.append(wid)
            }
            // If rotation became empty somehow, reinitialize
            if rotationOrder.count < 2 {
                rotationOrder = windowIDs
            }
        }

        // Find current front window in the rotation and step in the right direction
        let frontWID = windowIDs[0]
        guard let currentIndex = rotationOrder.firstIndex(of: frontWID) else { return }
        let count = rotationOrder.count
        let targetIndex: Int
        switch direction {
        case .forward:
            targetIndex = (currentIndex + 1) % count
        case .reverse:
            targetIndex = (currentIndex - 1 + count) % count
        }
        let targetWID = rotationOrder[targetIndex]
        guard let targetElement = idToElement[targetWID] else { return }

        AXUIElementPerformAction(targetElement, kAXRaiseAction as CFString)
        AXUIElementSetAttributeValue(
            targetElement,
            kAXMainAttribute as CFString,
            kCFBooleanTrue
        )
    }
}
