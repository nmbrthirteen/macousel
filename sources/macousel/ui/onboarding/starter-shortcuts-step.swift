import SwiftUI
import WindowSystem

struct StarterShortcutsStep: View {
  let preferences: Preferences

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var practice = ShortcutPractice()
  @State private var tap = PracticeKeyTap()

  var body: some View {
    OnboardingStepLayout(
      hero: OnboardingHero(
        frames: OnboardingScenes.shortcuts(keys: preferences.primaryKeys(for:)),
        description: "Shortcuts move focus, move a window, change its width, and open the overview"),
      title: "Shortcuts to start",
      subtitle: "Try each one now. Change any of them later in Settings."
    ) {
      Grid(alignment: .leading, verticalSpacing: Metrics.Spacing.compact) {
        ForEach(ShortcutPractice.starterActions, id: \.self) { action in
          row(
            action.title, keys: preferences.primaryKeys(for: action) ?? "Not set",
            done: practice.isPracticed(action))
        }
        row(
          "Jump to a column", keys: Self.columnJumpKeys(in: preferences.shortcuts),
          done: practice.isPracticed(ShortcutPractice.columnJump))
      }
      .onAppear {
        tap.start { hotkey in practice.record(hotkey, shortcuts: preferences.shortcuts) }
      }
      .onDisappear { tap.stop() }
    }
  }

  static func columnJumpKeys(in shortcuts: [Action: [Hotkey]]) -> String {
    guard let first = shortcuts[.focusColumn(Action.places.lowerBound)]?.first,
      let last = shortcuts[.focusColumn(Action.places.upperBound)]?.first
    else { return "Not set" }
    return "\(first.displayString) to \(last.displayString)"
  }

  private func row(_ title: String, keys: String, done: Bool) -> some View {
    GridRow {
      Image(systemName: done ? "checkmark.circle.fill" : "circle")
        .foregroundStyle(done ? Color.accentColor : Color.secondary)
        .contentTransition(.symbolEffect(.replace))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: done)
        .accessibilityHidden(true)
      Text(title)
      Text(keys)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .gridColumnAlignment(.trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .accessibilityElement(children: .combine)
    .accessibilityValue(done ? "Done" : "Not tried yet")
  }
}
