import WindowSystem

final class SystemGestureInput: GestureInput {
  private let scrollTap = ScrollGestureTap()
  private let swipes = SwipeGestureMonitor()

  var onScroll: ((_ deltaX: Double, _ phase: ScrollGestureTap.Phase) -> Void)? {
    get { scrollTap.onScroll }
    set { scrollTap.onScroll = newValue }
  }

  var onSwipe: ((_ share: Double, _ phase: ScrollGestureTap.Phase) -> Void)? {
    get { swipes.onSwipe }
    set { swipes.onSwipe = newValue }
  }

  func startScrolling(modifiers: Hotkey.Modifiers) {
    scrollTap.modifiers = modifiers
    _ = scrollTap.start()
  }

  func stopScrolling() {
    scrollTap.stop()
  }

  func startSwiping(fingerCount: Int) {
    swipes.fingerCount = fingerCount
    _ = swipes.start()
  }

  func stopSwiping() {
    swipes.stop()
  }
}
