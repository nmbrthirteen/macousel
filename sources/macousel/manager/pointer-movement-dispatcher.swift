import CoreGraphics

final class PointerMovementDispatcher {
  private let store: PreferencesStore
  private let pointer: any PointerDevice
  private let handlers: [(CGPoint) -> Void]

  init(
    store: PreferencesStore, pointer: any PointerDevice, handlers: [(CGPoint) -> Void]
  ) {
    self.store = store
    self.pointer = pointer
    self.handlers = handlers
  }

  func configure(isTiling: Bool) {
    pointer.stopObservingMovement()
    let preferences = store.preferences
    guard isTiling, preferences.focusFollowsMouse || preferences.displayFollowsPointer else {
      return
    }
    pointer.startObservingMovement { [weak self] point in
      self?.handlers.forEach { $0(point) }
    }
  }

  func stop() {
    pointer.stopObservingMovement()
  }
}
