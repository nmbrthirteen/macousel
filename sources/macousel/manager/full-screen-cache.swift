import CoreGraphics

final class FullScreenCache {
  private var answers: [CGWindowID: Bool] = [:]

  subscript(window: CGWindowID) -> Bool? {
    get { answers[window] }
    set { answers[window] = newValue }
  }

  func retain(only alive: Set<CGWindowID>) {
    answers = answers.filter { alive.contains($0.key) }
  }
}
