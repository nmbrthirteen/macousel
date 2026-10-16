import SwiftUI

struct MacouselApp: App {
  @NSApplicationDelegateAdaptor private var delegate: AppDelegate

  var body: some Scene {
    MenuBarExtra {
      MenuBarContent(
        manager: delegate.manager, updater: delegate.updater, store: delegate.store,
        diagnostics: delegate.diagnostics, onShowWelcome: delegate.onboarding.show)
    } label: {
      MenuBarLabel(manager: delegate.manager, store: delegate.store)
    }
    .menuBarExtraStyle(.menu)

    Window("Settings", id: SettingsWindow.id) {
      PersistedSettingsView(
        store: delegate.store, manager: delegate.manager, updater: delegate.updater,
        diagnostics: delegate.diagnostics, onShowWelcome: delegate.onboarding.show
      )
      .windowFullScreenBehavior(.disabled)
      .dimsWindowButtons(.miniaturizeButton, .zoomButton)
    }
    .defaultSize(width: Metrics.Size.settingsWidth, height: Metrics.Size.settingsHeight)
    .windowResizability(.contentMinSize)
    .defaultLaunchBehavior(.suppressed)
    .restorationBehavior(.disabled)
    .commands { SettingsCommands() }
  }
}
