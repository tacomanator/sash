import SwiftUI
import AppKit

struct ShortcutRecorder: View {
    @Binding var shortcut: KeyShortcut?
    @State private var isRecording = false
    @State private var monitor: Any?

    // Key codes for modifier keys themselves (ignore these during recording)
    private static let modifierKeyCodes: Set<UInt16> = [
        54, 55,  // Right/Left Command
        56, 60,  // Left/Right Shift
        58, 61,  // Left/Right Option
        59, 62,  // Left/Right Control
        63,      // Function
    ]

    var body: some View {
        HStack(spacing: 4) {
            Button(action: toggleRecording) {
                Text(buttonLabel)
                    .foregroundColor(isRecording ? .secondary : .primary)
                    .frame(minWidth: 120)
            }

            if shortcut != nil && !isRecording {
                Button(action: clearShortcut) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .onDisappear { stopRecording() }
    }

    private var buttonLabel: String {
        if isRecording { return "Type shortcut…" }
        return shortcut?.displayString ?? "Record Shortcut"
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        HotkeyManager.shared.unregister()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard !Self.modifierKeyCodes.contains(event.keyCode) else { return event }

            // Require at least one non-shift modifier
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard mods.contains(.command) || mods.contains(.option) || mods.contains(.control) else {
                return event
            }

            let newShortcut = KeyShortcut(keyCode: event.keyCode, modifiers: event.modifierFlags)
            shortcut = newShortcut
            newShortcut.save()
            HotkeyManager.shared.register(newShortcut)
            stopRecording()
            return nil // consume the event
        }
    }

    private func stopRecording() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        isRecording = false
        // Re-register current shortcut if recording was cancelled
        if let shortcut = shortcut {
            HotkeyManager.shared.register(shortcut)
        }
    }

    private func clearShortcut() {
        HotkeyManager.shared.unregister()
        shortcut = nil
        KeyShortcut.clear()
    }
}
