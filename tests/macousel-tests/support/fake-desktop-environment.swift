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
  private(set) var accessibilityRequests = 0
  private(set) var isObserving = false
  private var spaces: [String: UInt64] = [:]
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
