import AppKit
import StripCore
import WindowSystem
import os

final class LayoutPresenter {
  private static let narrowestVisibleEntrance: CGFloat = 40
  private static let signposter = OSSignposter(subsystem: "dev.macousel.app", category: "layout")

  let overlays: OverlayPresenter
  var excludedWindow: CGWindowID?

  private let state: TilingState
  private let tracker: WindowTracker
  private let store: PreferencesStore
  private let applier = FrameApplier()
  private let ticker = FrameTicker()
  private var requestedFrames: [CGWindowID: CGRect] = [:]

  init(
    state: TilingState, tracker: WindowTracker, store: PreferencesStore,
    overlays: OverlayPresenter
  ) {
    self.state = state
    self.tracker = tracker
    self.store = store
    self.overlays = overlays
    ticker.onFrame = { [weak self] deltaTime in self?.advance(by: deltaTime) }
  }

  var isSettled: Bool { !ticker.isRunning && applier.isIdle }

  func requestedFrame(for window: CGWindowID) -> CGRect? {
    requestedFrames[window]
  }

  func relayout() {
    let snapping = skipsAnimation
    state.activeKeys.forEach { retarget($0, snapping: snapping) }
    render()
    if hasUnsettledMotion { ticker.start() }
  }

  func track(_ key: Workspace.Key) {
    retarget(key, snapping: true)
    render()
  }

  func render() {
    let interval = Self.signposter.beginInterval("render")
    defer { Self.signposter.endInterval("render", interval) }
    var layouts: [Workspace.Key: StripLayout] = [:]
    for key in state.activeKeys {
      guard let display = state.display(for: key), let layout = state.animatedLayout(for: key)
      else { continue }
      place(layout, on: display)
      layouts[key] = layout
    }
    overlays.render(layouts)
  }

  func pauseAnimation() {
    ticker.stop()
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
      applier.forget(window)
    }
  }

  func halt() {
    ticker.stop()
    applier.flush()
    overlays.hide()
    requestedFrames = [:]
  }

  private var skipsAnimation: Bool {
    store.preferences.animationSpeed == .off
      || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
      || ProcessInfo.processInfo.isLowPowerModeEnabled
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
      guard let frame = tracker.windows[placement.window.rawValue]?.frame,
        display.frame.intersection(frame).width >= Self.narrowestVisibleEntrance
      else { continue }
      origins[placement.window] = frame.origin
    }
    return origins
  }

  private func advance(by deltaTime: Double) {
    for key in state.activeKeys {
      state.workspaces[key]?.motion.advance(by: deltaTime)
    }
    if !hasUnsettledMotion {
      for key in state.activeKeys { state.workspaces[key]?.motion.snap() }
      ticker.stop()
    }
    render()
  }

  private func place(_ layout: StripLayout, on display: Display) {
    let policy = state.parkingPolicy(for: display)
    for placement in layout.placements {
      let id = placement.window.rawValue
      guard id != excludedWindow, let window = tracker.windows[id] else { continue }
      let frame = policy.frame(for: placement, in: display.visibleFrame)
      guard requestedFrames[id] != frame else { continue }
      requestedFrames[id] = frame
      applier.submit(frame, for: window)
    }
  }
}
