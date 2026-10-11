import SwiftUI
import WindowSystem

struct StarterShortcutsStep: View {
  private static let starterActions: [Action] = [
    .focusLeft, .focusRight, .moveLeft, .moveRight, .cycleWidth,
  ]

  let store: PreferencesStore

  var body: some View {
    OnboardingStepLayout(title: "Five shortcuts to start") {
      Form {
        ForEach(Self.starterActions, id: \.self) { action in
          LabeledContent(action.title) {
            Text(binding(for: action))
              .monospacedDigit()
          }
        }
      }
      .formStyle(.grouped)
      .scrollDisabled(true)
      CaptionText("Change any of them in Settings > Shortcuts.")
    }
  }

  private func binding(for action: Action) -> String {
    store.preferences.shortcuts[action]?.first?.displayString ?? "Not set"
  }
}
