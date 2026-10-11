import SwiftUI
import WindowSystem

struct StarterShortcutsStep: View {
  private static let starterActions: [Action] = [
    .focusLeft, .focusRight, .moveLeft, .moveRight, .cycleWidth, .stackLeft,
  ]

  let store: PreferencesStore

  var body: some View {
    OnboardingStepLayout(title: "Seven shortcuts to start") {
      Form {
        ForEach(Self.starterActions, id: \.self) { action in
          LabeledContent(action.title) {
            Text(binding(for: action))
              .monospacedDigit()
          }
        }
        LabeledContent("Jump to a column") {
          Text(Self.columnJumpKeys(in: store.preferences.shortcuts))
            .monospacedDigit()
        }
      }
      .formStyle(.grouped)
      .scrollDisabled(true)
      CaptionText("Or drag a window onto the middle of another to stack them.")
      CaptionText("Change any of them in Settings > Shortcuts.")
    }
  }

  static func columnJumpKeys(in shortcuts: [Action: [Hotkey]]) -> String {
    guard let first = shortcuts[.focusColumn(Action.places.lowerBound)]?.first,
      let last = shortcuts[.focusColumn(Action.places.upperBound)]?.first
    else { return "Not set" }
    return "\(first.displayString) to \(last.displayString)"
  }

  private func binding(for action: Action) -> String {
    store.preferences.shortcuts[action]?.first?.displayString ?? "Not set"
  }
}
