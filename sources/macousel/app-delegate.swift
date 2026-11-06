import AppKit
import WindowSystem
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
  private static let logger = Logger(subsystem: Log.subsystem, category: "commands")
  private static let loggedHostLength = 40

  let store: PreferencesStore
  let manager: WindowManager
  let onboarding: OnboardingWindowController
  let updater: Updater
  let diagnostics: DiagnosticsAction
  let settings: SettingsWindowController
  private var menuBar: MenuBarController?
  private let dockPolicy: DockPolicy
  private let whatsNew = WhatsNewWindowController()
  private let terminationSignals = TerminationSignals()
  private var isDuplicate = false

  override init() {
    let store = PreferencesStore()
    self.store = store
    manager = WindowManager(store: store)
    let onboarding = OnboardingWindowController(store: store)
    self.onboarding = onboarding
    updater = Updater(
      feed: GitHubReleaseFeed(), installer: UpdateInstaller.running(),
      currentVersion: BundleInfo(bundle: .main).version, store: store)
    diagnostics = DiagnosticsAction(store: store, engineReport: { [manager] in await manager.engineReport() })
    let dockPolicy = DockPolicy(store: store)
    self.dockPolicy = dockPolicy
    settings = SettingsWindowController(onVisibilityChange: { dockPolicy.hasOpenWindow = $0 })
    super.init()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Two copies would share one engine service name and both move every window.
    if let other = Self.otherRunningCopy() {
      Self.logger.error("Another copy of Macousel is running, quitting this one")
      isDuplicate = true
      other.activate()
      NSApp.terminate(nil)
      return
    }
    terminationSignals.install()
    dockPolicy.start()
    if #unavailable(macOS 15) { closeSettingsWindow() }
    menuBar = MenuBarController(
      manager: manager, updater: updater, store: store, diagnostics: diagnostics,
      showSettings: { [settings] in settings.show(section: $0) }, showWelcome: onboarding.show)
    manager.start()
    let pendingNotes = PendingReleaseNotes(defaults: .standard)
      .take(for: BundleInfo(bundle: .main).version)
    if !onboarding.showIfNeeded(), let pendingNotes, !pendingNotes.blocks.isEmpty {
      whatsNew.show(pendingNotes)
    }
    updater.startAutomaticChecks()
  }

  private func closeSettingsWindow() {
    for window in NSApp.windows
    where window.identifier?.rawValue.hasPrefix(SettingsWindowController.windowID) == true {
      window.close()
    }
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    guard !isDuplicate else { return false }
    settings.show()
    return false
  }

  // Closing Settings leaves the menu bar item, so the app keeps running.
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  func applicationWillTerminate(_ notification: Notification) {
    guard !isDuplicate else { return }
    manager.shutdown()
  }

  private static func otherRunningCopy() -> NSRunningApplication? {
    guard let identifier = Bundle.main.bundleIdentifier else { return nil }
    let current = NSRunningApplication.current
    return NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
      .first { $0 != current && !$0.isTerminated && $0.activationPolicy != .prohibited }
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    guard !isDuplicate else { return }
    for url in urls {
      if CommandURL.isReloadSettings(url) {
        store.reload()
        continue
      }
      guard let action = CommandURL.action(from: url) else {
        let host = String((url.host ?? "").prefix(Self.loggedHostLength))
        Self.logger.error("Ignored unknown command URL with host: \(host, privacy: .public)")
        continue
      }
      guard CommandURL.accepts(action) else {
        Self.logger.error("Ignored command URL for \(action.commandName, privacy: .public)")
        continue
      }
      manager.perform(action)
    }
  }
}
