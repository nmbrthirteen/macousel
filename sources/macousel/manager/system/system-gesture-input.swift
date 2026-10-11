import WindowSystem

final class SystemGestureInput: GestureInput {
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
    _ = tap.start()
  }

  func stopScrolling() {
    tap.scrollModifiers = []
  }

  func startSwiping(fingerCount: Int) {
    swipes.fingerCount = fingerCount
    _ = swipes.start()
  }

  func stopSwiping() {
    swipes.stop()
  }
}
