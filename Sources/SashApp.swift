import SwiftUI

@main
struct SashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Sash", systemImage: "rectangle.stack") {
            SettingsView()
        }
        .menuBarExtraStyle(.window)
    }
}
