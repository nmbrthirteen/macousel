import CoreGraphics

protocol PointerDevice: AnyObject {
  var location: CGPoint { get }
  var isPrimaryButtonDown: Bool { get }
  func warp(to point: CGPoint)
  func windowID(at point: CGPoint) -> CGWindowID?
  func serverBounds(of window: CGWindowID) -> CGRect?
  func startObservingMovement(_ handler: @escaping (CGPoint) -> Void)
  func stopObservingMovement()
  func startObservingPrimaryButton(_ handler: @escaping (PrimaryButtonEvent) -> Void)
  func stopObservingPrimaryButton()
  func startObservingEscape(_ handler: @escaping () -> Void)
  func stopObservingEscape()
}
