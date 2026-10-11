import WindowSystem

protocol GestureInput: AnyObject {
  var onScroll: ((_ deltaX: Double, _ phase: ScrollGesturePhase) -> Void)? { get set }
  var onSwipe: ((_ share: Double, _ phase: ScrollGesturePhase) -> Void)? { get set }
  func startScrolling(modifiers: Hotkey.Modifiers)
  func stopScrolling()
  func startSwiping(fingerCount: Int)
  func stopSwiping()
}
