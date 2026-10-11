import SwiftUI

struct AppRulesPane: View {
  @Bindable var store: PreferencesStore
  @State private var runningApps = RunningApps()

  var body: some View {
    SettingsForm {
      Section {
        if store.preferences.appRules.isEmpty {
          CaptionText("No app rules yet.")
        }
        ForEach($store.preferences.appRules) { $rule in
          AppRuleRow(rule: $rule) { remove(rule) }
        }
      } header: {
        Text("Apps")
      } footer: {
        CaptionText("Windows of these apps float, open at a set width, or open in a set slot on the strip.")
      }

      Section {
        Menu("Add a running app") {
          ForEach(addableApps) { app in
            Button { add(app) } label: { AppLabel(identity: app) }
          }
        }
        .disabled(addableApps.isEmpty)
        Button("Restore default rules", action: restoreDefaults)
          .disabled(store.preferences.appRules == AppRule.defaults)
      }
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
