import CoreGraphics
import WindowSystem

protocol DesktopEnvironment: AnyObject {
  var isAccessibilityGranted: Bool { get }
  var displays: [Display] { get }
  var frontmostProcessID: pid_t? { get }
  var reducesMotion: Bool { get }
  var isLowPowerModeEnabled: Bool { get }
  var onDisplaysChanged: (() -> Void)? { get set }
  var onSpaceChanged: (() -> Void)? { get set }
  func requestAccessibilityAccess()
  func currentSpace(of display: Display) -> UInt64
  func onScreenWindowIDs() -> Set<CGWindowID>
  func startObserving()
  func stopObserving()
}
