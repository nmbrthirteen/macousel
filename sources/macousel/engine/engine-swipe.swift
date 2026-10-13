import StripCore
import WindowSystem

final class EngineSwipe {
  private let gestures: any GestureInput
  private let store: PreferencesStore
  private let commands: any EngineCommanding
  private let position: () -> StripPosition?
  private let isSuppressed: () -> Bool
  private var stepper = SwipeStepper()
  private var column: Int?

  init(
    gestures: any GestureInput, store: PreferencesStore, commands: any EngineCommanding,
    position: @escaping () -> StripPosition?, isSuppressed: @escaping () -> Bool
  ) {
    self.gestures = gestures
    self.store = store
    self.commands = commands
    self.position = position
    self.isSuppressed = isSuppressed
    gestures.onSwipe = { [weak self] share, phase in self?.swiped(by: share, phase: phase) }
  }

  func configure(isRunning: Bool) {
    gestures.stopSwiping()
    let preferences = store.preferences
    guard isRunning, preferences.swipeGestureEnabled, preferences.swipeStep == .column else {
      return
    }
    gestures.startSwiping(fingerCount: preferences.swipeFingers)
  }

  func stop() {
    gestures.stopSwiping()
    reset()
  }

  private func swiped(by share: Double, phase: ScrollGesturePhase) {
    if phase == .began { reset() }
    guard !isSuppressed() else { return }
    let preferences = store.preferences
    let sensitivity = min(
      max(preferences.swipeSensitivity, Preferences.swipeSensitivityRange.lowerBound),
      Preferences.swipeSensitivityRange.upperBound)
    let towardEarlier = (preferences.reversesSwipeDirection ? -share : share) * sensitivity
    step(by: -stepper.advance(by: towardEarlier))
    if phase == .ended { reset() }
  }

  private func step(by columns: Int) {
    guard columns != 0, let strip = position(), strip.columnCount > 0 else { return }
    let current = column ?? strip.focusedIndex
    let target = min(max(current + columns, 0), strip.columnCount - 1)
    column = target
    let words = ["window", "focus", target > current ? "east" : "west"]
    for _ in 0..<abs(target - current) {
      Task { await commands.send(words) }
    }
  }

  private func reset() {
    stepper = SwipeStepper()
    column = nil
  }
}
