import CoreGraphics

protocol FramePlacer: AnyObject {
  var isIdle: Bool { get }
  var onSlowAppChange: ((_ bundleIdentifier: String, _ isSlow: Bool) -> Void)? { get set }
  func isSlowApp(of window: any WindowHandle) -> Bool
  func seedSlowApps(_ bundleIdentifiers: Set<String>)
  func submit(_ frame: CGRect, for window: any WindowHandle)
  func afterPlacement(
    of window: any WindowHandle, within timeout: Duration, _ action: @escaping () -> Void)
  func flush()
  func forget(_ window: CGWindowID)
}
