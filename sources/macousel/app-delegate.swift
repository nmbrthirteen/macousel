import AppKit
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "commands")

  let store: PreferencesStore
  let manager: WindowManager
  let onboarding: OnboardingWindowController

  override init() {
    let store = PreferencesStore()
    self.store = store
    manager = WindowManager(store: store)
    onboarding = OnboardingWindowController(store: store)
    super.init()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    manager.start()
    onboarding.showIfNeeded()
  }

  func applicationWillTerminate(_ notification: Notification) {
    manager.shutdown()
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      guard let action = CommandURL.action(from: url) else {
        Self.logger.error("Ignored unknown command URL: \(url.absoluteString, privacy: .public)")
        continue
      }
      manager.perform(action)
    }
  }
}
