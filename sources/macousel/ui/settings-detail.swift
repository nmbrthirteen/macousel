import SwiftUI

struct SettingsDetail: View {
  let section: SettingsSection
  let store: PreferencesStore
  let manager: WindowManager
  let updater: Updater
  let diagnostics: DiagnosticsAction
  let onShowWelcome: () -> Void

  var body: some View {
    switch section {
    case .general: GeneralPane(store: store, manager: manager)
    case .layout: LayoutPane(store: store)
    case .motion: MotionPane(store: store)
    case .appRules: AppRulesPane(store: store)
    case .displays: DisplaysPane(store: store, manager: manager)
    case .shortcuts: ShortcutsPane(store: store)
    case .appShortcuts: AppShortcutsPane(store: store)
    case .pointer: PointerPane(store: store)
    case .macSetup: MacSetupPane(store: store)
    case .about: AboutPane(updater: updater, diagnostics: diagnostics, onShowWelcome: onShowWelcome)
    }
  }
}
