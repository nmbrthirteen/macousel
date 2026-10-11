import CoreGraphics
import StripCore
import WindowSystem
import os

final class FloatingWindowKeeper {
  static let raiseDelay = Duration.milliseconds(60)
  static let minimumOverlap: CGFloat = 8

  private static let logger = Logger(subsystem: "dev.macousel.app", category: "floating")

  var isSuppressed: () -> Bool = { false }

  private let state: TilingState
  private let source: any WindowSource
  private let environment: any DesktopEnvironment
  private let store: PreferencesStore
  private let clock: any AnimationClock
  private let scratchpad: Scratchpad
  private let frames: FloatingFrameCache
  private var focusedWindow: WindowID?
  private var generation = 0

  init(
    state: TilingState, source: any WindowSource, environment: any DesktopEnvironment,
    store: PreferencesStore, clock: any AnimationClock, scratchpad: Scratchpad,
    frames: FloatingFrameCache
  ) {
    self.state = state
    self.source = source
    self.environment = environment
    self.store = store
    self.clock = clock
    self.scratchpad = scratchpad
    self.frames = frames
  }

  func focusRequested(_ window: WindowID) {
    refreshFrames()
    schedule(for: window)
  }

  func focusObserved(_ window: WindowID) {
    guard state.activeKey(containing: window) != nil else {
      focusedWindow = nil
      return
    }
    guard focusedWindow != window else { return }
    refreshFrames()
    schedule(for: window)
  }

  func windowChanged(_ window: CGWindowID) {
    guard !state.isTiled(WindowID(window)) else { return }
    frames.invalidate(window)
    frames.refresh([window])
  }

  func refreshFrames(probed: [CGWindowID: WindowFacts] = [:]) {
    let floating = floatingWindows()
    frames.retain(only: Set(floating))
    for id in floating {
      if let frame = probed[id]?.frame { frames.record(frame, for: id) }
    }
    frames.refresh(floating)
  }

  func cancel() {
    generation += 1
    focusedWindow = nil
  }

  func overlappingWindows(of window: WindowID) -> [CGWindowID] {
    guard store.preferences.keepsFloatingWindowsOnTop,
      let key = state.activeKey(containing: window),
      let target = state.settledLayout(for: key)?[window]?.frame
    else { return [] }
    return floatingWindows().filter { id in
      frames.frame(of: id).map { Self.overlaps($0, target) } ?? false
    }
  }

  func canFocusWithoutRaising(_ window: WindowID) -> Bool {
    !state.sharesTabbedColumn(window) && !overlappingWindows(of: window).isEmpty
  }

  private func schedule(for window: WindowID) {
    generation += 1
    focusedWindow = window
    guard store.preferences.keepsFloatingWindowsOnTop else { return }
    let current = generation
    clock.schedule(after: Self.raiseDelay) { [weak self] in
      guard let self, generation == current else { return }
      raiseFloatingWindows(above: window)
    }
  }

  private func raiseFloatingWindows(above window: WindowID) {
    guard !isSuppressed() else { return }
    let covered = overlappingWindows(of: window)
    for id in covered.reversed() { source.window(id)?.raise() }
    Self.logger.info("Raised \(covered.count, privacy: .public) floating windows")
  }

  private func floatingWindows() -> [CGWindowID] {
    environment.orderedOnScreenWindowIDs().filter { id in
      source.window(id) != nil && !state.isTiled(WindowID(id)) && !scratchpad.isHidden(id)
    }
  }

  private static func overlaps(_ first: CGRect, _ second: CGRect) -> Bool {
    let shared = first.intersection(second)
    return !shared.isNull && shared.width > minimumOverlap && shared.height > minimumOverlap
  }
}
