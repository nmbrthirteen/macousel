import SwiftUI

struct MenuBarLabel: View {
  let manager: WindowManager
  let store: PreferencesStore

  var body: some View {
    MenuBarLabelView(
      presentation: MenuBarPresentation(
        status: manager.status, position: manager.position,
        indicator: store.preferences.menuBarIndicator))
  }
}
