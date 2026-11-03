import AppKit
import Observation
import WindowSystem

@Observable
final class MacSetupChecks {
  private(set) var checks: [SetupCheck] = []
  @ObservationIgnored private var activation: Task<Void, Never>?
  @ObservationIgnored private var yabaiCheck: Task<Void, Never>?
  @ObservationIgnored private var runsYabai = false
  @ObservationIgnored private let store: PreferencesStore
  @ObservationIgnored private let readers: SystemDefaultsReaders
  @ObservationIgnored private let bundleURL: URL

  init(
    store: PreferencesStore, readers: SystemDefaultsReaders = SystemDefaultsReaders(),
    bundleURL: URL = Bundle.main.bundleURL
  ) {
    self.store = store
    self.readers = readers
    self.bundleURL = bundleURL
  }

  func start() {
    refresh()
    activation?.cancel()
    activation = Task { [weak self] in
      for await _ in NotificationCenter.default.notifications(
        named: NSApplication.didBecomeActiveNotification)
      {
        self?.refresh()
      }
    }
  }

  func stop() {
    activation?.cancel()
    activation = nil
    yabaiCheck?.cancel()
    yabaiCheck = nil
  }

  func refresh() {
    rebuild()
    yabaiCheck?.cancel()
    yabaiCheck = Task { [weak self] in
      let running = await CompetingWindowManagers.isYabaiRunning()
      guard let self, !Task.isCancelled, running != self.runsYabai else { return }
      self.runsYabai = running
      self.rebuild()
    }
  }

  private func rebuild() {
    let preferences = store.preferences
    let swipe = SwipeGestureCheck(
      trackpads: readers.trackpads, isSwipeEnabled: preferences.swipeGestureEnabled,
      fingers: preferences.swipeFingers)
    let location = InstallLocationCheck(
      bundleURL: bundleURL, homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
    checks =
      [accessibilityCheck, location.check]
      + SystemSettingsChecks(readers: readers).all
      + [swipe.check].compactMap { $0 }
      + [competitorsCheck(running: CompetingWindowManagers.running(includingYabai: runsYabai))]
  }

  private var accessibilityCheck: SetupCheck {
    let isGranted = AccessibilityPermission.isGranted
    return SetupCheck(
      id: "accessibility",
      passingTitle: "Accessibility access granted",
      attentionTitle: "Accessibility access needed",
      effect: "Without it Macousel cannot move or resize windows.",
      location: "System Settings > Privacy & Security > Accessibility",
      isPassing: isGranted,
      fix: .init(title: "Open System Settings", perform: AccessibilityPermission.openSystemSettings)
    )
  }

  private func competitorsCheck(running names: [String]) -> SetupCheck {
    SetupCheck(
      id: "competitors",
      passingTitle: "No other window manager is running",
      attentionTitle: "Another window manager is running",
      effect: "Two window managers move the same windows and undo each other.",
      location: "that app, or System Settings > General > Login Items",
      isPassing: names.isEmpty,
      offenders: names
    )
  }
}
