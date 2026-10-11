import CoreGraphics

@testable import Macousel

@MainActor
final class FakePointerDevice: PointerDevice {
  var location = CGPoint.zero
  var isPrimaryButtonDown = false
  var windowAtPoint: (CGPoint) -> CGWindowID? = { _ in nil }
  var serverBoundsProvider: (CGWindowID) -> CGRect? = { _ in nil }
  var isObservingMovement: Bool { movementHandler != nil }
  var isObservingEscape: Bool { escapeHandler != nil }
  var isObservingPrimaryButton: Bool { buttonHandler != nil }
  private(set) var warps: [CGPoint] = []
  private(set) var serverBoundsReadCount = 0
  private var serverBoundsOverrides: [CGWindowID: CGRect] = [:]
  private var movementHandler: ((CGPoint) -> Void)?
  private var buttonHandler: ((PrimaryButtonEvent) -> Void)?
  private var escapeHandler: (() -> Void)?

  func warp(to point: CGPoint) {
    warps.append(point)
    location = point
  }

  func windowID(at point: CGPoint) -> CGWindowID? {
    windowAtPoint(point)
  }

  func serverBounds(of window: CGWindowID) -> CGRect? {
    serverBoundsReadCount += 1
    return serverBoundsOverrides[window] ?? serverBoundsProvider(window)
  }

  func setServerBounds(_ bounds: CGRect?, of window: CGWindowID) {
    serverBoundsOverrides[window] = bounds
  }

  func startObservingMovement(_ handler: @escaping (CGPoint) -> Void) {
    movementHandler = handler
  }

  func stopObservingMovement() {
    movementHandler = nil
  }

  func startObservingPrimaryButton(_ handler: @escaping (PrimaryButtonEvent) -> Void) {
    buttonHandler = handler
  }

  func stopObservingPrimaryButton() {
    buttonHandler = nil
  }

  func startObservingEscape(_ handler: @escaping () -> Void) {
    escapeHandler = handler
  }

  func stopObservingEscape() {
    escapeHandler = nil
  }

  func moveTo(_ point: CGPoint) {
    location = point
    movementHandler?(point)
  }

  func pressPrimary(at point: CGPoint) {
    location = point
    isPrimaryButtonDown = true
    buttonHandler?(.pressed(at: point))
  }

  func dragPrimary(to point: CGPoint) {
    location = point
    buttonHandler?(.dragged)
  }

  func releasePrimary(sendingEvent: Bool = true) {
    isPrimaryButtonDown = false
    if sendingEvent { buttonHandler?(.released) }
  }

  func movePrimarySilently(to point: CGPoint) {
    location = point
  }

  func pressEscape() {
    escapeHandler?()
  }
}
