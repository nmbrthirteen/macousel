import SwiftUI

struct AppRulesPane: View {
  @Bindable var store: PreferencesStore
  @State private var runningApps = RunningApps()
  @State private var confirmsRestore = false

  var body: some View {
    SettingsForm {
      SettingsGroup(title: "Floating windows") {
        AppRulesPreview(
          config: store.preferences.layout,
          keepsFloatingOnTop: store.preferences.keepsFloatingWindowsOnTop)
        ToggleRow(
          title: "Keep floating windows above tiled windows",
          isOn: $store.preferences.keepsFloatingWindowsOnTop,
          detail: "After you focus a tiled window, floating windows it covers come back to the front.",
          unavailable: EngineFeature.floatingWindowsOnTop.unavailableCaption(
            for: store.preferences.engine))
      }

      SettingsGroup(title: "Apps", footer: "A rule applies to every window of the app.") {
        if store.preferences.appRules.isEmpty {
          CaptionText("No app rules yet. Add a running app to set one.")
        }
        ForEach($store.preferences.appRules) { $rule in
          AppRuleRow(rule: $rule) { remove(rule) }
        }
      }

      Section {
        Menu("Add a running app") {
          ForEach(addableApps) { app in
            Button { add(app) } label: { AppLabel(identity: app) }
          }
        }
        .disabled(addableApps.isEmpty)
        Button("Restore default rules") { confirmsRestore = true }
          .disabled(store.preferences.appRules == AppRule.defaults)
      }
    }
    .confirmationDialog("Restore default rules?", isPresented: $confirmsRestore) {
      Button("Restore defaults", role: .destructive, action: restoreDefaults)
    } message: {
      Text("This replaces your app rules with the defaults.")
    }
    .onAppear(perform: runningApps.start)
    .onDisappear(perform: runningApps.stop)
  }

  private var addableApps: [AppIdentity] {
    runningApps.excluding(Set(store.preferences.appRules.map(\.bundleIdentifier)))
  }

  private func add(_ app: AppIdentity) {
    store.preferences.appRules.append(AppRule(bundleIdentifier: app.id, behavior: .float))
  }

  private func restoreDefaults() {
    store.preferences.appRules = AppRule.defaults
  }

  private func remove(_ rule: AppRule) {
    store.preferences.appRules.removeAll { $0.id == rule.id }
  }
}
