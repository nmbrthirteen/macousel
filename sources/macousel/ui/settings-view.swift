import SwiftUI

struct SettingsView: View {
  let store: PreferencesStore
  let manager: WindowManager
  let updater: Updater
  let diagnostics: DiagnosticsAction
  let onShowWelcome: () -> Void
  @Binding var selection: SettingsSection
  @State private var query = ""
  @State private var history: SettingsHistory

  init(
    store: PreferencesStore, manager: WindowManager, updater: Updater,
    diagnostics: DiagnosticsAction, onShowWelcome: @escaping () -> Void,
    selection: Binding<SettingsSection>
  ) {
    self.store = store
    self.manager = manager
    self.updater = updater
    self.diagnostics = diagnostics
    self.onShowWelcome = onShowWelcome
    _selection = selection
    _history = State(initialValue: SettingsHistory(current: selection.wrappedValue))
  }

  var body: some View {
    NavigationSplitView {
      SettingsSidebar(selection: visited, query: query)
        .searchable(text: $query, placement: .sidebar, prompt: "Search settings")
        .navigationSplitViewColumnWidth(
          min: Metrics.Size.sidebarMinWidth, ideal: Metrics.Size.sidebarIdealWidth,
          max: Metrics.Size.sidebarMaxWidth
        )
    } detail: {
      SettingsDetail(
        section: history.current, store: store, manager: manager, updater: updater,
        diagnostics: diagnostics, onShowWelcome: onShowWelcome)
        .navigationTitle(history.current.title)
        .toolbar { toolbar }
    }
    .frame(minWidth: Metrics.Size.settingsMinWidth, minHeight: Metrics.Size.settingsMinHeight)
    .onChange(of: selection) { history.visit(selection) }
    .onChange(of: history.current) { selection = history.current }
  }

  private var visited: Binding<SettingsSection> {
    Binding(get: { history.current }, set: { history.visit($0) })
  }

  @ToolbarContentBuilder
  private var toolbar: some ToolbarContent {
    ToolbarItem(placement: .navigation) {
      ControlGroup {
        Button("Back", systemImage: "chevron.backward") { history.goBack() }
          .disabled(!history.canGoBack)
          .keyboardShortcut("[")
        Button("Forward", systemImage: "chevron.forward") { history.goForward() }
          .disabled(!history.canGoForward)
          .keyboardShortcut("]")
      }
      .controlGroupStyle(.navigation)
    }
    ToolbarItem(placement: .primaryAction) {
      TilingStatusButton(manager: manager)
    }
  }
}
