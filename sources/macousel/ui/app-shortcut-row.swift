import SwiftUI
import WindowSystem

struct AppShortcutRow: View {
  let bundleIdentifier: String
  let hotkey: Hotkey?
  let startsRecording: Bool
  let onRemove: () -> Void
  @State private var recording: ShortcutRecording

  init(
    bundleIdentifier: String, hotkey: Hotkey?, store: PreferencesStore,
    startsRecording: Bool = false, onStop: @escaping () -> Void = {},
    onRemove: @escaping () -> Void
  ) {
    self.bundleIdentifier = bundleIdentifier
    self.hotkey = hotkey
    self.startsRecording = startsRecording
    self.onRemove = onRemove
    let recording = ShortcutRecording(target: .app(bundleIdentifier), store: store)
    recording.onStop = onStop
    _recording = State(initialValue: recording)
  }

  var body: some View {
    CaptionedRow {
      LabeledContent {
        HStack(spacing: Metrics.Spacing.regular) {
          AppShortcutChip(recording: recording, hotkey: hotkey, appName: identity.name)
          RemoveButton(label: "Remove shortcut for \(identity.name)", action: onRemove)
        }
      } label: {
        AppLabel(identity: identity)
      }
      if let message = recording.message {
        ErrorText(message)
      }
    }
    .onAppear {
      if startsRecording { recording.start() }
    }
    .onDisappear(perform: recording.stop)
  }

  private var identity: AppIdentity {
    AppIdentity(bundleIdentifier: bundleIdentifier)
  }
}
