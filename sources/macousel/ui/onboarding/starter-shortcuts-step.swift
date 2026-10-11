import SwiftUI
import WindowSystem

struct StarterShortcutsStep: View {
  private static let starterActions: [Action] = [
    .focusLeft, .focusRight, .moveLeft, .moveRight, .stackLeft, .cycleWidth, .toggleOverview,
  ]

  let store: PreferencesStore

  var body: some View {
    OnboardingStepLayout(title: "Shortcuts to start") {
      OnboardingForm(height: OnboardingMetrics.shortcutsHeight) {
        ForEach(Self.starterActions.prefix(4), id: \.self) { action in
          row(for: action)
        }
        LabeledContent("Jump to a column") {
          Text(Self.columnJumpKeys(in: store.preferences.shortcuts))
            .monospacedDigit()
        }
        ForEach(Self.starterActions.dropFirst(4), id: \.self) { action in
          row(for: action)
        }
      }
      CaptionText("Drag a window onto the middle of another to stack them.")
      CaptionText("Change any shortcut in Settings > Shortcuts.")
    }
  }

  static func columnJumpKeys(in shortcuts: [Action: [Hotkey]]) -> String {
    guard let first = shortcuts[.focusColumn(Action.places.lowerBound)]?.first,
      let last = shortcuts[.focusColumn(Action.places.upperBound)]?.first
    else { return "Not set" }
    return "\(first.displayString) to \(last.displayString)"
  }

  private func row(for action: Action) -> some View {
    LabeledContent(action.title) {
      Text(store.preferences.shortcuts[action]?.first?.displayString ?? "Not set")
        .monospacedDigit()
    }
  }
}
