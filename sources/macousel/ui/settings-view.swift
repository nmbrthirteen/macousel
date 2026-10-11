import SwiftUI

struct SettingsView: View {
  let store: PreferencesStore
  let manager: WindowManager
  let onShowWelcome: () -> Void
  @Binding var selection: SettingsSection
  @State private var query = ""

  var body: some View {
    NavigationSplitView {
      SettingsSidebar(selection: $selection, query: query)
        .searchable(text: $query, placement: .sidebar, prompt: "Search")
        .navigationSplitViewColumnWidth(
          min: Metrics.Size.sidebarMinWidth, ideal: Metrics.Size.sidebarIdealWidth,
          max: Metrics.Size.sidebarMaxWidth
        )
    } detail: {
      SettingsDetail(section: selection, store: store, manager: manager, onShowWelcome: onShowWelcome)
        .navigationTitle(selection.title)
    }
    .frame(minWidth: Metrics.Size.settingsMinWidth, minHeight: Metrics.Size.settingsMinHeight)
  }
}
