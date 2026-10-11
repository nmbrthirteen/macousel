import StripCore
import WindowSystem

final class ScrollInteraction {
  private static let wheelIdleDelay = Duration.milliseconds(180)
  private static let swipeTravelPerPadWidth = 2.4
  private static let scrollModifiers: Hotkey.Modifiers = [.control, .option]
  private static let velocitySmoothing = 0.7
  private static let longestVelocitySample = Duration.milliseconds(100)
  private static let fastestMomentum = 5000.0

  private struct Gesture {
    var key: Workspace.Key
    var startOffset: Double
    var unresistedOffset: Double
    var velocity = 0.0
    var lastSample: ContinuousClock.Instant
    var idleTimeout: Task<Void, Never>?
  }

  private let state: TilingState
  private let presenter: LayoutPresenter
  private let focus: FocusDriver
  private let store: PreferencesStore
  private let gestures: any GestureInput
  private let now: () -> ContinuousClock.Instant
  private var gesture: Gesture?

  init(
    state: TilingState, presenter: LayoutPresenter, focus: FocusDriver, store: PreferencesStore,
    gestures: any GestureInput, now: @escaping () -> ContinuousClock.Instant
  ) {
    self.state = state
    self.presenter = presenter
    self.focus = focus
    self.store = store
    self.gestures = gestures
    self.now = now
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

  private func swiped(byPadShare share: Double, phase: ScrollGesturePhase) {
    guard let key = gesture?.key ?? state.pointerKey, let display = state.display(for: key)
    else { return }
    let sensitivity = min(
      max(store.preferences.swipeSensitivity, Preferences.swipeSensitivityRange.lowerBound),
      Preferences.swipeSensitivityRange.upperBound)
    let travel =
      share * state.usableWidth(of: display) * Self.swipeTravelPerPadWidth * sensitivity
    scrolled(by: travel, phase: phase)
  }

  private func scrolled(by rawDeltaX: Double, phase: ScrollGesturePhase) {
    let deltaX = store.preferences.reversesSwipeDirection ? -rawDeltaX : rawDeltaX
    if phase == .began || gesture == nil {
      guard begin() else { return }
    }
    guard let key = gesture?.key else { return }
    drag(key, by: deltaX, updatesVelocity: deltaX != 0 || phase != .ended)
    presenter.track(key)
    presenter.overlays.flashMinimap(for: key, update: .immediate)

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
    gesture = Gesture(
      key: key, startOffset: workspace.scrollOffset, unresistedOffset: workspace.scrollOffset,
      lastSample: now())
    presenter.pauseAnimation()
    return true
  }

  private func drag(_ key: Workspace.Key, by deltaX: Double, updatesVelocity: Bool) {
    guard var gesture, let display = state.display(for: key) else { return }
    gesture.unresistedOffset -= deltaX
    if updatesVelocity {
      gesture.velocity = smoothedVelocity(of: gesture, after: -deltaX)
      gesture.lastSample = now()
    }
    self.gesture = gesture
    let resisted = RubberBand.resisted(
      gesture.unresistedOffset, within: state.scrollRange(of: key),
      dimension: state.usableWidth(of: display))
    state.workspaces[key]?.gestureOffset = resisted
  }

  private func smoothedVelocity(of gesture: Gesture, after travel: Double) -> Double {
    let elapsed = gesture.lastSample.duration(to: now())
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

    let isStale = gesture.lastSample.duration(to: now()) > Self.longestVelocitySample
    let velocity =
      carryingMomentum && !isStale
      ? min(max(gesture.velocity, -Self.fastestMomentum), Self.fastestMomentum) : 0
    let projection = Spring.projectionTime(response: workspace.motion.response)
    let restingOffset = workspace.scrollOffset + velocity * projection
    let intent = SwipeIntent(
      travel: gesture.unresistedOffset - gesture.startOffset, velocity: velocity,
      usableWidth: state.usableWidth(of: display))
    let previousFocus = workspace.strip.focusedWindow
    workspace.gestureOffset = nil
    workspace.strip.settle(
      at: restingOffset, intent: intent, viewportWidth: display.visibleFrame.width,
      config: state.config)
    workspace.motion.impart(horizontalVelocity: -velocity)
    state.workspaces[key] = workspace
    state.focusedKey = key
    if let focused = workspace.strip.focusedWindow, focused != previousFocus {
      focus.activate(focused, in: key, from: .pointer) { presenter.relayout() }
    } else {
      presenter.relayout()
    }
  }
}
