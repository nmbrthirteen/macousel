import Observation
import WindowSystem

@Observable
final class ShortcutPractice {
  static let starterActions: [Action] = [
    .focusLeft, .focusRight, .moveLeft, .moveRight, .cycleWidth, .toggleOverview,
  ]
  static let columnJump = Action.focusColumn(Action.places.lowerBound)

  private(set) var practiced: Set<Action> = []

  func isPracticed(_ action: Action) -> Bool {
    practiced.contains(action)
  }

  func record(_ hotkey: Hotkey, shortcuts: [Action: [Hotkey]]) {
    for (action, hotkeys) in shortcuts where hotkeys.contains(hotkey) {
      if case .focusColumn = action {
        practiced.insert(Self.columnJump)
      } else if Self.starterActions.contains(action) {
        practiced.insert(action)
      }
    }
  }
}
