import AppKit
import SwiftUI
import WindowSystem

struct GeneralPane: View {
  @Bindable var store: PreferencesStore
  let manager: WindowManager
  @State private var accessibility = AccessibilityStatus()
  @State private var launchAtLogin = LaunchAtLogin()

  var body: some View {
    SettingsForm {
      SettingsGroup(title: "Permissions") {
        AccessibilityStatusRow(
          status: accessibility,
          grant: .init(
            title: "Open System Settings\u{2026}", perform: AccessibilityGuide.shared.begin))
      }

      SettingsGroup(title: "Engine") {
        Picker(selection: $store.preferences.engine) {
          ForEach(WindowEngine.allCases, id: \.self) { engine in
            Text(engine.title).tag(engine)
          }
        } label: {
          RowLabel(title: "Engine", detail: store.preferences.engine.summary)
        }
        if let notice = manager.notice {
          ErrorText(notice)
        }
      }

      SettingsGroup(title: "Startup") {
        ToggleRow(title: "Launch at login", isOn: launchAtLoginBinding)
        if let message = launchAtLogin.errorMessage {
          ErrorText(message)
        }
        ToggleRow(title: "Restore layout on launch", isOn: $store.preferences.restoresSession)
      }

      SettingsGroup(title: "Appearance") {
        ToggleRow(title: "Show in Dock", isOn: $store.preferences.showsInDock)
      }

      SettingsGroup(title: "Updates") {
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
