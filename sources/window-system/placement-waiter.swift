final class PlacementWaiter {
  private var action: (() -> Void)?

  init(_ action: @escaping () -> Void) {
    self.action = action
  }

  func fire() {
    guard let action else { return }
    self.action = nil
    action()
  }
}
