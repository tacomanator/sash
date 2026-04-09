import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @State private var shortcut: KeyShortcut? = KeyShortcut.load()
    @State private var hasAccessibility = AccessibilityHelper.checkPermission()
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sash")
                .font(.headline)

            HStack {
                Text("Shortcut:")
                ShortcutRecorder(shortcut: $shortcut)
            }

            if !hasAccessibility {
                accessibilityWarning
            }

            Divider()

            HStack {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .toggleStyle(.checkbox)
                    .onChange(of: launchAtLogin) { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("[Sash] Launch at login error: \(error)")
                            // Revert on failure
                            launchAtLogin = !newValue
                        }
                    }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .controlSize(.small)
            }
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            hasAccessibility = AccessibilityHelper.checkPermission()
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        .onReceive(Timer.publish(every: 2, on: .main, in: .common).autoconnect()) { _ in
            hasAccessibility = AccessibilityHelper.checkPermission()
        }
    }

    private var accessibilityWarning: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text("Accessibility access required")
                    .font(.caption)
                Spacer()
                Button("Open Settings") {
                    AccessibilityHelper.openAccessibilitySettings()
                }
                .controlSize(.small)
            }
            Text("If Sash is already listed, remove it with \u{2212} then re-add it.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
