import SwiftUI
import WindowSystem

struct ShortcutRow: View {
  static let unavailableCaption = "Not available with the Paneru engine"

  let action: Action
  @Bindable var store: PreferencesStore
  @State private var recording: ShortcutRecording

  init(action: Action, store: PreferencesStore) {
    self.action = action
    self.store = store
    _recording = State(initialValue: ShortcutRecording(target: .action(action), store: store))
  }

  var body: some View {
    CaptionedRow {
      LabeledContent(action.title) {
        HStack(spacing: Metrics.Spacing.compact) {
          ForEach(hotkeys, id: \.self) { hotkey in
            RemovableChip(
              title: hotkey.displayString, removeLabel: "Remove \(hotkey.displayString) from \(action.title)"
            ) { remove(hotkey) }
          }
          ShortcutAddButton(recording: recording, label: "Add shortcut for \(action.title)")
        }
      }
      .modifier(EngineGated(isSupported: action.isSupported(by: engine)))
      if let message = recording.message {
        ErrorText(message)
      }
      if hasUnavailableHotkey {
        CaptionText(Self.unavailableCaption)
      }
    }
    .onDisappear(perform: recording.stop)
  }

  private var engine: WindowEngine { store.preferences.engine }

  private var hasUnavailableHotkey: Bool {
    engine == .paneru && action.isSupported(by: engine)
      && action.paneruSupport != .handledByMacousel
      && hotkeys.contains { !PaneruChord.isAvailable($0) }
  }

  private var hotkeys: [Hotkey] {
    store.preferences.shortcuts[action] ?? []
  }

  private func remove(_ hotkey: Hotkey) {
    store.preferences.shortcuts[action]?.removeAll { $0 == hotkey }
  }
}
