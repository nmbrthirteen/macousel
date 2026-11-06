import SwiftUI

struct MacouselApp: App {
  @NSApplicationDelegateAdaptor private var delegate: AppDelegate

  // Command URLs go to AppDelegate. Without the empty match, SwiftUI also opens a scene
  // for each one.
  var body: some Scene {
    Window("Settings opener", id: SettingsWindowController.openerWindowID) {
      SettingsOpenerCapture(settings: delegate.settings)
    }
    .windowResizability(.contentSize)
    .handlesExternalEvents(matching: [])
    .notRestored()

    Window("Settings", id: SettingsWindowController.windowID) {
      PersistedSettingsView(
        store: delegate.store, manager: delegate.manager, updater: delegate.updater,
        diagnostics: delegate.diagnostics, onShowWelcome: delegate.onboarding.show
      )
      .fullScreenDisabled()
      .dimsWindowButtons(.miniaturizeButton, .zoomButton)
      .onAppear(perform: delegate.settings.windowDidAppear)
      .onDisappear(perform: delegate.settings.windowDidClose)
    }
    .defaultSize(width: Metrics.Size.settingsWidth, height: Metrics.Size.settingsHeight)
    .windowResizability(.contentMinSize)
    .handlesExternalEvents(matching: [])
    .hiddenAtLaunch()
    .commands { SettingsCommands(showSettings: { delegate.settings.show() }) }
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

  fileprivate func notRestored() -> some Scene {
    if #available(macOS 15, *) {
      return restorationBehavior(.disabled)
    } else {
      return self
    }
  }
}
