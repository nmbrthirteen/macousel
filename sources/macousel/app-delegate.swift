import AppKit
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "commands")

  let store: PreferencesStore
  let manager: WindowManager
  let onboarding: OnboardingWindowController
  let updater: Updater
  let diagnostics: DiagnosticsAction
  private let terminationSignals = TerminationSignals()

  override init() {
    let store = PreferencesStore()
    self.store = store
    manager = WindowManager(store: store)
    onboarding = OnboardingWindowController(store: store)
    updater = Updater(
      feed: GitHubReleaseFeed(), installer: UpdateInstaller.running(),
      currentVersion: BundleInfo(bundle: .main).version, store: store)
    diagnostics = DiagnosticsAction(store: store)
    super.init()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    terminationSignals.install()
    manager.start()
    onboarding.showIfNeeded()
    updater.startAutomaticChecks()
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
