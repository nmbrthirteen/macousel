import CoreGraphics

protocol FramePlacer: AnyObject {
  var isIdle: Bool { get }
  var slowestRecentApplySeconds: Double { get }
  func submit(_ frame: CGRect, for window: any WindowHandle)
  func flush()
  func forget(_ window: CGWindowID)
}
