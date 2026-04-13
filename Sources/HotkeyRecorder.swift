import SwiftUI
import AppKit

struct HotkeyRecorder: View {
    @Binding var hotkey: Hotkey?
    var direction: CycleDirection = .forward
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

            if hotkey != nil && !isRecording {
                Button(action: clearHotkey) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .onDisappear { stopRecording() }
    }

    private var buttonLabel: String {
        if isRecording { return "Type hotkey…" }
        return hotkey?.displayString ?? "Record Hotkey"
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        HotkeyManager.shared.unregister(direction)
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard !Self.modifierKeyCodes.contains(event.keyCode) else { return event }

            // Require at least one non-shift modifier
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard mods.contains(.command) || mods.contains(.option) || mods.contains(.control) else {
                return event
            }

            let newHotkey = Hotkey(keyCode: event.keyCode, modifiers: event.modifierFlags)
            hotkey = newHotkey
            newHotkey.save(for: direction)
            HotkeyManager.shared.register(newHotkey, for: direction)
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
        // Re-register current hotkey if recording was cancelled
        if let hotkey = hotkey {
            HotkeyManager.shared.register(hotkey, for: direction)
        }
    }

    private func clearHotkey() {
        HotkeyManager.shared.unregister(direction)
        hotkey = nil
        Hotkey.clear(for: direction)
    }
}
