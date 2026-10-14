import SwiftUI
import WindowSystem

struct StarterShortcutsStep: View {
  private static let starterActions: [Action] = [
    .focusLeft, .focusRight, .moveLeft, .moveRight, .cycleWidth, .toggleOverview,
  ]

  let preferences: Preferences

  var body: some View {
    OnboardingStepLayout(
      hero: OnboardingHero(
        frames: OnboardingScenes.shortcuts(keys: preferences.primaryKeys(for:)),
        description: "Shortcuts move focus, move a window, change its width, and open the overview"),
      title: "Shortcuts to start",
      subtitle: "Change any of them later in Settings."
    ) {
      Grid(alignment: .leading, verticalSpacing: Metrics.Spacing.compact) {
        ForEach(Self.starterActions, id: \.self) { action in
          row(action.title, keys: preferences.primaryKeys(for: action) ?? "Not set")
        }
        row("Jump to a column", keys: Self.columnJumpKeys(in: preferences.shortcuts))
      }
    }
  }

  static func columnJumpKeys(in shortcuts: [Action: [Hotkey]]) -> String {
    guard let first = shortcuts[.focusColumn(Action.places.lowerBound)]?.first,
      let last = shortcuts[.focusColumn(Action.places.upperBound)]?.first
    else { return "Not set" }
    return "\(first.displayString) to \(last.displayString)"
  }

  private func row(_ title: String, keys: String) -> some View {
    GridRow {
      Text(title)
      Text(keys)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .gridColumnAlignment(.trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
  }
}
