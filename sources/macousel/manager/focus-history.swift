import CoreGraphics

nonisolated struct FocusHistory: Equatable, Sendable {
  private(set) var current: CGWindowID?
  private(set) var previous: CGWindowID?

  mutating func note(_ window: CGWindowID) {
    guard window != current else { return }
    previous = current
    current = window
  }
}
