import SwiftUI

struct MacSetupPane: View {
  @State private var setup: MacSetupChecks

  init(store: PreferencesStore) {
    _setup = State(initialValue: MacSetupChecks(store: store))
  }

  var body: some View {
    SettingsForm {
      Section {
        ForEach(setup.checks) { check in
          StatusRow(
            isPassing: check.isPassing, title: check.title, detail: check.detail,
            action: check.isPassing ? nil : check.fix)
        }
      }
    }
    .onAppear(perform: setup.start)
    .onDisappear(perform: setup.stop)
  }
}
