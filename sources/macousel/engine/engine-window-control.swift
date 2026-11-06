import CoreGraphics

protocol EngineWindowControl: AnyObject {
  func raise(_ windows: [CGWindowID])
  func focus(_ window: CGWindowID)
  func move(_ window: CGWindowID, to frame: CGRect)
}
