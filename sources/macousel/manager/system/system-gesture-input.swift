import WindowSystem
import os

final class SystemGestureInput: GestureInput {
  private static let logger = Logger(subsystem: Log.subsystem, category: "input-event-tap")

  private let tap: InputEventTap
  private let swipes = SwipeGestureMonitor()

  init(tap: InputEventTap) {
    self.tap = tap
  }

  var onScroll: ((_ deltaX: Double, _ phase: ScrollGesturePhase) -> Void)? {
    get { tap.onScroll }
    set { tap.onScroll = newValue }
  }

  var onSwipe: ((_ share: Double, _ phase: ScrollGesturePhase) -> Void)? {
    get { swipes.onSwipe }
    set { swipes.onSwipe = newValue }
  }

  func startScrolling(modifiers: Hotkey.Modifiers) {
    tap.scrollModifiers = modifiers
    if !tap.start(for: .scroll) { Self.logger.error("Could not start the scroll gesture tap") }
  }

  func stopScrolling() {
    tap.scrollModifiers = []
    tap.stop(for: .scroll)
  }

  func startSwiping(fingerCount: Int) {
    swipes.fingerCount = fingerCount
    if !swipes.start() { Self.logger.error("Could not start the trackpad swipe monitor") }
  }

  func stopSwiping() {
    swipes.stop()
  }
}
