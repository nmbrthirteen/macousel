import SwiftUI

struct ShortcutRecorder: View {
  @State private var recording: ShortcutRecording

  init(action: Action, store: PreferencesStore) {
    _recording = State(initialValue: ShortcutRecording(target: .action(action), store: store))
  }

  var body: some View {
    HStack(spacing: Metrics.Spacing.compact) {
      if let message = recording.message {
        ErrorText(message)
      }
      Button(
        recording.isRecording ? "Press keys, Esc to cancel" : "Add shortcut",
        systemImage: "plus", action: recording.toggle
      )
      .labelStyle(.titleAndIcon)
      .controlSize(.small)
    }
    .onDisappear(perform: recording.stop)
  }
}
