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
      .fullScreenDisabled()
      .dimsWindowButtons(.miniaturizeButton, .zoomButton)
    }
    .defaultSize(width: Metrics.Size.settingsWidth, height: Metrics.Size.settingsHeight)
    .windowResizability(.contentMinSize)
    .hiddenAtLaunch()
    .commands { SettingsCommands() }
  }
}

extension View {
  @ViewBuilder
  fileprivate func fullScreenDisabled() -> some View {
    if #available(macOS 15, *) {
      windowFullScreenBehavior(.disabled)
    } else {
      self
    }
  }
}

extension Scene {
  // macOS 14 has neither modifier, so AppDelegate closes the window at launch instead.
  fileprivate func hiddenAtLaunch() -> some Scene {
    if #available(macOS 15, *) {
      return defaultLaunchBehavior(.suppressed).restorationBehavior(.disabled)
    } else {
      return self
    }
  }
}
