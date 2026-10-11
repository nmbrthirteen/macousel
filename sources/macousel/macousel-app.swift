import SwiftUI

struct MacouselApp: App {
  @NSApplicationDelegateAdaptor private var delegate: AppDelegate

  var body: some Scene {
    MenuBarExtra("Macousel", systemImage: "rectangle.split.3x1") {
      MenuBarContent(manager: delegate.manager, onShowWelcome: delegate.onboarding.show)
    }
    .menuBarExtraStyle(.menu)

    Window("Settings", id: SettingsWindow.id) {
      PersistedSettingsView(
        store: delegate.store, manager: delegate.manager, onShowWelcome: delegate.onboarding.show)
    }
    .defaultSize(width: Metrics.Size.settingsWidth, height: Metrics.Size.settingsHeight)
    .windowResizability(.contentMinSize)
    .defaultLaunchBehavior(.suppressed)
    .restorationBehavior(.disabled)
    .commands { SettingsCommands() }
  }
}
