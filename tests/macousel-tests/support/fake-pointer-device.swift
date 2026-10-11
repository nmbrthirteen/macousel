import CoreGraphics

@testable import Macousel

@MainActor
final class FakePointerDevice: PointerDevice {
  var location = CGPoint.zero
  var isPrimaryButtonDown = false
  var windowAtPoint: (CGPoint) -> CGWindowID? = { _ in nil }
  private(set) var warps: [CGPoint] = []
  private var movementHandler: ((CGPoint) -> Void)?
  private var releaseHandler: (() -> Void)?

  func warp(to point: CGPoint) {
    warps.append(point)
    location = point
  }

  func windowID(at point: CGPoint) -> CGWindowID? {
    windowAtPoint(point)
  }

  func startObservingMovement(_ handler: @escaping (CGPoint) -> Void) {
    movementHandler = handler
  }

  func stopObservingMovement() {
    movementHandler = nil
  }

  func startObservingPrimaryRelease(_ handler: @escaping () -> Void) {
    releaseHandler = handler
  }

  func stopObservingPrimaryRelease() {
    releaseHandler = nil
  }

  func moveTo(_ point: CGPoint) {
    location = point
    movementHandler?(point)
  }

  func pressPrimary(at point: CGPoint) {
    location = point
    isPrimaryButtonDown = true
  }

  func releasePrimary() {
    isPrimaryButtonDown = false
    releaseHandler?()
  }
}
