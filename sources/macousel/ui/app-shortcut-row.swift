import SwiftUI
import WindowSystem

struct AppShortcutRow: View {
  let bundleIdentifier: String
  let hotkey: Hotkey?
  @Bindable var store: PreferencesStore
  var startsRecording = false
  var onStop: () -> Void = {}
  let onRemove: () -> Void

  var body: some View {
    LabeledContent {
      HStack(spacing: Metrics.Spacing.regular) {
        AppShortcutChip(
          bundleIdentifier: bundleIdentifier, hotkey: hotkey, store: store,
          startsRecording: startsRecording, onStop: onStop)
        RemoveButton(label: "Remove shortcut for \(identity.name)", action: onRemove)
      }
    } label: {
      AppLabel(identity: identity)
    }
  }

  private var identity: AppIdentity {
    AppIdentity(bundleIdentifier: bundleIdentifier)
  }
}
