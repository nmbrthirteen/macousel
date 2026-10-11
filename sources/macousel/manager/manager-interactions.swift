import CoreGraphics

final class ManagerInteractions {
  private let drag: DragInteraction
  private let scrolling: ScrollInteraction
  private let displayFollowsPointer: DisplayFollowsPointer
  private let pointerMovement: PointerMovementDispatcher
  private let resizes: ResizeAdoption

  init(
    state: TilingState, source: any WindowSource, presenter: LayoutPresenter, focus: FocusDriver,
    store: PreferencesStore, ports: ManagerPorts
  ) {
    let drag = DragInteraction(
      state: state, source: source, presenter: presenter, pointer: ports.pointer)
    let scrolling = ScrollInteraction(
      state: state, presenter: presenter, focus: focus, store: store, gestures: ports.gestures,
      now: { ports.clock.now })
    let hover = FocusFollowsPointer(
      state: state, presenter: presenter, focus: focus, store: store, pointer: ports.pointer)
    let displayFollowsPointer = DisplayFollowsPointer(
      state: state, presenter: presenter, focus: focus, store: store, pointer: ports.pointer)
    let isSuppressed: () -> Bool = { drag.isActive || scrolling.isActive }
    hover.isSuppressed = isSuppressed
    displayFollowsPointer.isSuppressed = isSuppressed
    self.drag = drag
    self.scrolling = scrolling
    self.displayFollowsPointer = displayFollowsPointer
    pointerMovement = PointerMovementDispatcher(
      store: store, pointer: ports.pointer, tiledDisplayCount: { state.tiledDisplays.count },
      handlers: [
        { point in hover.pointerMoved(to: point) },
        { point in displayFollowsPointer.pointerMoved(to: point) },
      ])
    resizes = ResizeAdoption(
      state: state, source: source, presenter: presenter, pointer: ports.pointer)
  }

  var isGestureActive: Bool { drag.isActive || scrolling.isActive }

  func start() {
    drag.start()
  }

  func configure(isTiling: Bool) {
    scrolling.configure(isTiling: isTiling)
    pointerMovement.configure(isTiling: isTiling)
    if !isTiling {
      displayFollowsPointer.stop()
      resizes.stop()
    }
  }

  func stop() {
    drag.stop()
    scrolling.stop()
    pointerMovement.stop()
    displayFollowsPointer.stop()
    resizes.stop()
  }

  func displaysSynchronized() {
    pointerMovement.refresh()
  }

  func windowMoved(_ window: CGWindowID) {
    drag.windowChanged(window)
  }

  func windowResized(_ window: CGWindowID) {
    drag.windowChanged(window)
    resizes.windowResized(window)
  }
}
