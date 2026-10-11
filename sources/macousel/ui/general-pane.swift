import AppKit
import SwiftUI
import WindowSystem

struct GeneralPane: View {
  @Bindable var store: PreferencesStore
  @State private var accessibility = AccessibilityStatus()
  @State private var launchAtLogin = LaunchAtLogin()

  var body: some View {
    SettingsForm {
      Section("Permissions") {
        AccessibilityStatusRow(
          status: accessibility,
          grant: .init(
            title: "Open System Settings", perform: AccessibilityPermission.openSystemSettings))
      }

      Section("Startup") {
        ToggleRow(title: "Launch at login", isOn: launchAtLoginBinding)
        if let message = launchAtLogin.errorMessage {
          ErrorText(message)
        }
        ToggleRow(title: "Restore layout on launch", isOn: $store.preferences.restoresSession)
      }

      Section("Updates") {
        ToggleRow(
          title: "Check for updates automatically", isOn: $store.preferences.checksForUpdates)
      }

      SettingsFileSection(store: store)
    }
    .onAppear(perform: launchAtLogin.refresh)
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
      launchAtLogin.refresh()
    }
  }

  private var launchAtLoginBinding: Binding<Bool> {
    Binding(get: { launchAtLogin.isEnabled }, set: { launchAtLogin.set($0) })
  }
}
