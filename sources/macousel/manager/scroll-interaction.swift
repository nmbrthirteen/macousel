import StripCore
import WindowSystem

final class ScrollInteraction {
  private static let wheelIdleDelay = Duration.milliseconds(180)
  private static let swipeTravelPerPadWidth = 1.6
  private static let scrollModifiers: Hotkey.Modifiers = [.control, .option]
  private static let velocitySmoothing = 0.7
  private static let longestVelocitySample = Duration.milliseconds(100)
  private static let momentumProjection = 0.18
  private static let fastestMomentum = 6000.0

  private struct Gesture {
    var key: Workspace.Key
    var unresistedOffset: Double
    var velocity = 0.0
    var lastSample = ContinuousClock.now
    var idleTimeout: Task<Void, Never>?
  }

  private let state: TilingState
  private let presenter: LayoutPresenter
  private let focus: FocusDriver
  private let store: PreferencesStore
  private let gestures: any GestureInput
  private var gesture: Gesture?

  init(
    state: TilingState, presenter: LayoutPresenter, focus: FocusDriver, store: PreferencesStore,
    gestures: any GestureInput
  ) {
    self.state = state
    self.presenter = presenter
    self.focus = focus
    self.store = store
    self.gestures = gestures
    gestures.onScroll = { [weak self] deltaX, phase in self?.scrolled(by: deltaX, phase: phase) }
    gestures.onSwipe = { [weak self] share, phase in self?.swiped(byPadShare: share, phase: phase) }
  }

  var isActive: Bool { gesture != nil }

  func configure(isTiling: Bool) {
    stop()
    guard isTiling else { return }
    if store.preferences.scrollGestureEnabled {
      gestures.startScrolling(modifiers: Self.scrollModifiers)
    }
    if store.preferences.swipeGestureEnabled {
      gestures.startSwiping(fingerCount: store.preferences.swipeFingers)
    }
  }

  func stop() {
    gestures.stopScrolling()
    gestures.stopSwiping()
    gesture?.idleTimeout?.cancel()
    if let key = gesture?.key { state.workspaces[key]?.gestureOffset = nil }
    gesture = nil
  }

  private func swiped(byPadShare share: Double, phase: ScrollGestureTap.Phase) {
    guard let key = gesture?.key ?? state.pointerKey, let display = state.display(for: key)
    else { return }
    let travel = share * state.usableWidth(of: display) * Self.swipeTravelPerPadWidth
    scrolled(by: travel, phase: phase)
  }

  private func scrolled(by deltaX: Double, phase: ScrollGestureTap.Phase) {
    if phase == .began || gesture == nil {
      guard begin() else { return }
    }
    guard let key = gesture?.key else { return }
    drag(key, by: deltaX)
    presenter.track(key)
    presenter.overlays.flashMinimap(for: key)

    if phase == .ended {
      finish(carryingMomentum: true)
    } else {
      finishAfterIdle()
    }
  }

  private func begin() -> Bool {
    guard let key = state.pointerKey, let workspace = state.workspaces[key],
      !workspace.strip.isEmpty
    else { return false }
    gesture?.idleTimeout?.cancel()
    gesture = Gesture(key: key, unresistedOffset: workspace.scrollOffset)
    presenter.pauseAnimation()
    return true
  }

  private func drag(_ key: Workspace.Key, by deltaX: Double) {
    guard var gesture, let display = state.display(for: key) else { return }
    gesture.unresistedOffset -= deltaX
    gesture.velocity = smoothedVelocity(of: gesture, after: -deltaX)
    gesture.lastSample = .now
    self.gesture = gesture
    let resisted = RubberBand.resisted(
      gesture.unresistedOffset, within: state.scrollRange(of: key),
      dimension: state.usableWidth(of: display))
    state.workspaces[key]?.gestureOffset = resisted
  }

  private func smoothedVelocity(of gesture: Gesture, after travel: Double) -> Double {
    let elapsed = ContinuousClock.now - gesture.lastSample
    guard elapsed > .zero, elapsed < Self.longestVelocitySample else { return gesture.velocity }
    let seconds =
      Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
    let instantaneous = travel / seconds
    return Self.velocitySmoothing * instantaneous
      + (1 - Self.velocitySmoothing) * gesture.velocity
  }

  private func finishAfterIdle() {
    gesture?.idleTimeout?.cancel()
    gesture?.idleTimeout = Task {
      try? await Task.sleep(for: Self.wheelIdleDelay)
      if !Task.isCancelled { finish(carryingMomentum: false) }
    }
  }

  private func finish(carryingMomentum: Bool) {
    guard let gesture else { return }
    gesture.idleTimeout?.cancel()
    self.gesture = nil
    let key = gesture.key
    guard let display = state.display(for: key), var workspace = state.workspaces[key]
    else { return }

    let velocity =
      carryingMomentum
      ? min(max(gesture.velocity, -Self.fastestMomentum), Self.fastestMomentum) : 0
    let restingOffset = workspace.scrollOffset + velocity * Self.momentumProjection
    let previousFocus = workspace.strip.focusedWindow
    workspace.gestureOffset = nil
    workspace.strip.settle(
      at: restingOffset, viewportWidth: display.visibleFrame.width, config: state.config)
    workspace.motion.impart(horizontalVelocity: -velocity)
    state.workspaces[key] = workspace
    state.focusedKey = key
    if let focused = workspace.strip.focusedWindow, focused != previousFocus {
      focus.activate(focused, in: key, from: .pointer)
    }
    presenter.relayout()
  }
}
