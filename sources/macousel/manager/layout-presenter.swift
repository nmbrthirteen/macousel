import CoreGraphics
import StripCore
import WindowSystem
import os

final class LayoutPresenter {
  private static let narrowestVisibleEntrance: CGFloat = 40
  private static let signposter = OSSignposter(subsystem: "dev.macousel.app", category: "layout")

  let overlays: OverlayPresenter
  private let indicator: StripPositionIndicator
  var excludedWindow: CGWindowID?

  private let state: TilingState
  private let source: any WindowSource
  private let environment: any DesktopEnvironment
  private let store: PreferencesStore
  private let placer: any FramePlacer
  private let clock: any AnimationClock
  private let admissionFrames: AdmissionFrames
  private var requestedFrames: [CGWindowID: CGRect] = [:]
  private var sizeRequestTimes: [CGWindowID: ContinuousClock.Instant] = [:]
  private let growth = GrowthPlanner()
  private var slowSubmissions = SlowSubmissionLimiter()

  init(
    state: TilingState, source: any WindowSource, environment: any DesktopEnvironment,
    store: PreferencesStore, placer: any FramePlacer, clock: any AnimationClock,
    overlays: OverlayPresenter, indicator: StripPositionIndicator,
    admissionFrames: AdmissionFrames
  ) {
    self.state = state
    self.source = source
    self.environment = environment
    self.store = store
    self.placer = placer
    self.clock = clock
    self.overlays = overlays
    self.indicator = indicator
    self.admissionFrames = admissionFrames
    clock.onFrame = { [weak self] deltaTime in self?.advance(by: deltaTime) }
  }

  var isSettled: Bool { !clock.isRunning && placer.isIdle }

  func requestedFrame(for window: CGWindowID) -> CGRect? {
    requestedFrames[window]
  }

  func sizeRequestAge(of window: CGWindowID) -> Duration? {
    sizeRequestTimes[window].map { $0.duration(to: clock.now) }
  }

  func relayout() {
    let snapping = skipsAnimation
    state.activeKeys.forEach { retarget($0, snapping: snapping) }
    admissionFrames.clear()
    if !snapping { advanceMotion(by: clock.frameInterval) }
    slowSubmissions.endTracking()
    render()
    if hasUnsettledMotion { clock.start() }
  }

  func track(_ key: Workspace.Key) {
    retarget(key, snapping: true)
    slowSubmissions.beginTracking()
    render()
  }

  func render() {
    let interval = Self.signposter.beginInterval("render")
    defer { Self.signposter.endInterval("render", interval) }
    var layouts: [Workspace.Key: StripLayout] = [:]
    for key in state.activeKeys {
      guard let display = state.display(for: key), let layout = state.animatedLayout(for: key)
      else { continue }
      place(
        layout, on: display, key: key,
        holdingGrowth: state.workspaces[key]?.motion.isSettled == false)
      layouts[key] = layout
    }
    overlays.render(layouts)
    indicator.refresh()
  }

  func pauseAnimation() {
    clock.stop()
  }

  func invalidate(_ window: CGWindowID) {
    requestedFrames[window] = nil
  }

  func invalidateAll() {
    requestedFrames = [:]
  }

  func retain(only alive: Set<CGWindowID>) {
    for window in requestedFrames.keys where !alive.contains(window) {
      requestedFrames[window] = nil
      placer.forget(window)
    }
    sizeRequestTimes = sizeRequestTimes.filter { alive.contains($0.key) }
    slowSubmissions.retain(only: alive)
  }

  func halt() {
    clock.stop()
    placer.flush()
    overlays.hide()
    requestedFrames = [:]
    sizeRequestTimes = [:]
  }

  private var skipsAnimation: Bool {
    store.preferences.animationSpeed == .off
      || environment.reducesMotion || environment.isLowPowerModeEnabled
  }

  private var hasUnsettledMotion: Bool {
    state.activeKeys.contains { state.workspaces[$0]?.motion.isSettled == false }
  }

  private func retarget(_ key: Workspace.Key, snapping: Bool) {
    guard let layout = state.targetLayout(for: key) else { return }
    if let response = store.preferences.animationSpeed.springResponse {
      state.workspaces[key]?.motion.setResponse(response)
    }
    let entering = snapping ? [:] : enteringOrigins(of: layout, in: key)
    state.workspaces[key]?.motion.retarget(to: layout, snapping: snapping, entering: entering)
  }

  private func enteringOrigins(
    of layout: StripLayout, in key: Workspace.Key
  ) -> [WindowID: CGPoint] {
    guard let motion = state.workspaces[key]?.motion, let display = state.display(for: key)
    else { return [:] }
    var origins: [WindowID: CGPoint] = [:]
    for placement in layout.placements where !motion.isTracking(placement.window) {
      guard
        let frame = admissionFrames.take(placement.window.rawValue)
          ?? source.window(placement.window.rawValue)?.frame,
        display.frame.intersection(frame).width >= Self.narrowestVisibleEntrance
      else { continue }
      origins[placement.window] = frame.origin
    }
    return origins
  }

  private func advanceMotion(by deltaTime: Double) {
    for key in state.activeKeys {
      state.workspaces[key]?.motion.advance(by: deltaTime)
    }
  }

  private func advance(by deltaTime: Double) {
    advanceMotion(by: deltaTime)
    if !hasUnsettledMotion {
      for key in state.activeKeys { state.workspaces[key]?.motion.snap() }
      clock.stop()
    }
    render()
  }

  private func place(
    _ layout: StripLayout, on display: Display, key: Workspace.Key, holdingGrowth: Bool
  ) {
    let policy = state.parkingPolicy(for: display)
    let settled = settledPlacements(ofSlowWindowsIn: layout, key: key, on: display)
    let planned = layout.placements.compactMap { animated -> PlannedFrame? in
      let id = animated.window.rawValue
      guard id != excludedWindow, source.window(id) != nil else { return nil }
      let placement = settled[animated.window] ?? animated
      let target = policy.frame(for: placement, in: display.visibleFrame)
      return PlannedFrame(
        window: id, placement: placement, target: target, previous: requestedFrames[id],
        isParked: target != placement.frame)
    }
    growth.submissions(for: planned, holdingGrowth: holdingGrowth).forEach { submit($0) }
  }

  private func settledPlacements(
    ofSlowWindowsIn layout: StripLayout, key: Workspace.Key, on display: Display
  ) -> [WindowID: Placement] {
    let slow = layout.placements.map(\.window).filter { window in
      source.window(window.rawValue).map { placer.isSlowApp(of: $0) } ?? false
    }
    guard !slow.isEmpty, let target = state.targetLayout(for: key) else { return [:] }
    var settled: [WindowID: Placement] = [:]
    for placement in target.placements where slow.contains(placement.window) {
      settled[placement.window] = placement.moved(
        to: placement.frame.origin, in: display.visibleFrame)
    }
    return settled
  }

  private func submit(_ submission: FrameSubmission) {
    let id = submission.window
    let previous = requestedFrames[id]
    guard previous != submission.frame, let window = source.window(id) else { return }
    if placer.isSlowApp(of: window) {
      guard slowSubmissions.permits(id, at: clock.now) else { return }
      slowSubmissions.record(id, at: clock.now)
    }
    if previous?.size != submission.frame.size { sizeRequestTimes[id] = clock.now }
    requestedFrames[id] = submission.frame
    placer.submit(submission.frame, for: window)
  }
}
