import CoreGraphics
import WindowSystem

@testable import Macousel

@MainActor
final class FakeDesktopEnvironment: DesktopEnvironment {
  var isAccessibilityGranted = true
  var bootSessionIdentifier = "boot-1"
  var displays: [Display]
  var frontmostProcessID: pid_t?
  var reducesMotion = false
  var isLowPowerModeEnabled = false
  var onDisplaysChanged: (() -> Void)?
  var onSpaceChanged: (() -> Void)?
  var runningBundleIdentifiers: Set<String> = []
  private(set) var activatedApps: [String] = []
  private(set) var launchedApps: [String] = []
  private(set) var accessibilityRequests = 0
  private(set) var isObserving = false
  private var spaces: [String: UInt64] = [:]
  private(set) var stackingOrder: [CGWindowID] = []
  private var onScreen: Set<CGWindowID> = []

  init(displays: [Display]) {
    self.displays = displays
  }

  func requestAccessibilityAccess() {
    accessibilityRequests += 1
  }

  func currentSpace(of display: Display) -> UInt64 {
    spaces[display.uuid] ?? 1
  }

  func onScreenWindowIDs() -> Set<CGWindowID> {
    onScreen
  }

  func orderedOnScreenWindowIDs() -> [CGWindowID] {
    stackingOrder.filter { onScreen.contains($0) } + onScreen.subtracting(stackingOrder).sorted()
  }

  func stack(frontToBack order: [CGWindowID]) {
    stackingOrder = order
  }

  func bringToFront(_ window: CGWindowID) {
    stackingOrder = [window] + orderedOnScreenWindowIDs().filter { $0 != window }
  }

  func isInFront(of window: CGWindowID, _ other: CGWindowID) -> Bool {
    let order = orderedOnScreenWindowIDs()
    guard let first = order.firstIndex(of: window), let second = order.firstIndex(of: other)
    else { return false }
    return first < second
  }

  func activateOrLaunch(bundleIdentifier: String) {
    if runningBundleIdentifiers.contains(bundleIdentifier) {
      activatedApps.append(bundleIdentifier)
    } else {
      launchedApps.append(bundleIdentifier)
    }
  }

  func startObserving() {
    isObserving = true
  }

  func stopObserving() {
    isObserving = false
  }

  func show(_ window: CGWindowID) {
    onScreen.insert(window)
  }

  func hide(_ window: CGWindowID) {
    onScreen.remove(window)
  }

  func switchSpace(of display: Display, to space: UInt64, showing windows: Set<CGWindowID>) {
    spaces[display.uuid] = space
    onScreen = windows
    onSpaceChanged?()
  }
}
