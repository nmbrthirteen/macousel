import CoreGraphics

final class PointerMovementDispatcher {
  private let store: PreferencesStore
  private let pointer: any PointerDevice
  private let tiledDisplayCount: () -> Int
  private let handlers: [(CGPoint) -> Void]
  private var isTiling = false
  private var isObserving = false

  init(
    store: PreferencesStore, pointer: any PointerDevice, tiledDisplayCount: @escaping () -> Int,
    handlers: [(CGPoint) -> Void]
  ) {
    self.store = store
    self.pointer = pointer
    self.tiledDisplayCount = tiledDisplayCount
    self.handlers = handlers
  }

  func configure(isTiling: Bool) {
    self.isTiling = isTiling
    pointer.stopObservingMovement()
    isObserving = false
    refresh()
  }

  func refresh() {
    let shouldObserve = isTiling && needsMovement
    guard shouldObserve != isObserving else { return }
    isObserving = shouldObserve
    guard shouldObserve else {
      pointer.stopObservingMovement()
      return
    }
    pointer.startObservingMovement { [weak self] point in
      self?.handlers.forEach { $0(point) }
    }
  }

  func stop() {
    isTiling = false
    isObserving = false
    pointer.stopObservingMovement()
  }

  private var needsMovement: Bool {
    let preferences = store.preferences
    return preferences.focusFollowsMouse
      || (preferences.displayFollowsPointer && tiledDisplayCount() >= 2)
  }
}
