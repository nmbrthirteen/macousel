import WindowSystem

@testable import Macousel

@MainActor
final class FakeGestureInput: GestureInput {
  var onScroll: ((_ deltaX: Double, _ phase: ScrollGestureTap.Phase) -> Void)?
  var onSwipe: ((_ share: Double, _ phase: ScrollGestureTap.Phase) -> Void)?
  private(set) var isScrolling = false
  private(set) var swipeFingerCount: Int?

  func startScrolling(modifiers: Hotkey.Modifiers) {
    isScrolling = true
  }

  func stopScrolling() {
    isScrolling = false
  }

  func startSwiping(fingerCount: Int) {
    swipeFingerCount = fingerCount
  }

  func stopSwiping() {
    swipeFingerCount = nil
  }
}
