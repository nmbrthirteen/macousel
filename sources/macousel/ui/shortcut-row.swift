import SwiftUI
import WindowSystem

struct ShortcutRow: View {
  let action: Action
  @Bindable var store: PreferencesStore

  var body: some View {
    LabeledContent(action.title) {
      HStack(spacing: Metrics.Spacing.compact) {
        ForEach(hotkeys, id: \.self) { hotkey in
          RemovableChip(title: hotkey.displayString) { remove(hotkey) }
        }
        ShortcutRecorder(action: action, store: store)
      }
    }
  }

  private var hotkeys: [Hotkey] {
    store.preferences.shortcuts[action] ?? []
  }

  private func remove(_ hotkey: Hotkey) {
    store.preferences.shortcuts[action]?.removeAll { $0 == hotkey }
  }
}
