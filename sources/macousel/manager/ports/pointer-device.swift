import CoreGraphics

protocol PointerDevice: AnyObject {
  var location: CGPoint { get }
  var isPrimaryButtonDown: Bool { get }
  func warp(to point: CGPoint)
  func windowID(at point: CGPoint) -> CGWindowID?
  func startObservingMovement(_ handler: @escaping (CGPoint) -> Void)
  func stopObservingMovement()
  func startObservingPrimaryRelease(_ handler: @escaping () -> Void)
  func stopObservingPrimaryRelease()
}
