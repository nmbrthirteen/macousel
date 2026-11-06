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
    LabeledContent {
      HStack(spacing: Metrics.Spacing.comfortable) {
        ForEach(hotkeys, id: \.self) { hotkey in
          KeycapChip(
            hotkey: hotkey, removeLabel: "Remove \(hotkey.displayString) from \(action.title)"
          ) { remove(hotkey) }
        }
        ShortcutAddButton(recording: recording, label: "Add shortcut for \(action.title)")
      }
    } label: {
      RowLabel(title: action.title, detail: caption)
    }
    .disabled(!isSupported)
    .onDisappear(perform: recording.stop)
    if let message = recording.message {
      ErrorText(message)
    }
  }

  private var engine: WindowEngine { store.preferences.engine }

  private var isSupported: Bool { action.isSupported(by: engine) }

  private var caption: String? {
    if !isSupported {
      return action.isPaneruOnly
        ? EngineFeature.paneruOnlyCaption : EngineFeature.unsupportedCaption
    }
    return hasUnavailableHotkey ? Self.unavailableCaption : nil
  }

  private var hasUnavailableHotkey: Bool {
    engine == .paneru && action.paneruSupport != .handledByMacousel
      && hotkeys.contains { !PaneruChord.isAvailable($0) }
  }

  private var hotkeys: [Hotkey] {
    store.preferences.shortcuts[action] ?? []
  }

  private func remove(_ hotkey: Hotkey) {
    store.preferences.shortcuts[action]?.removeAll { $0 == hotkey }
  }
}
