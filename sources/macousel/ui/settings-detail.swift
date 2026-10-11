import SwiftUI

struct SettingsDetail: View {
  let section: SettingsSection
  let store: PreferencesStore
  let manager: WindowManager
  let onShowWelcome: () -> Void

  var body: some View {
    switch section {
    case .general: GeneralPane(store: store)
    case .layout: LayoutPane(store: store)
    case .motion: MotionPane(store: store)
    case .appRules: AppRulesPane(store: store)
    case .displays: DisplaysPane(store: store, manager: manager)
    case .shortcuts: ShortcutsPane(store: store)
    case .pointer: PointerPane(store: store)
    case .macSetup: MacSetupPane()
    case .about: AboutPane(onShowWelcome: onShowWelcome)
    }
  }
}
