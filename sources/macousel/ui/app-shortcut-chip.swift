import SwiftUI
import WindowSystem

struct AppShortcutChip: View {
  @State private var recording: ShortcutRecording
  private let hotkey: Hotkey?
  private let startsRecording: Bool

  init(
    bundleIdentifier: String, hotkey: Hotkey?, store: PreferencesStore, startsRecording: Bool,
    onStop: @escaping () -> Void
  ) {
    let recording = ShortcutRecording(target: .app(bundleIdentifier), store: store)
    recording.onStop = onStop
    _recording = State(initialValue: recording)
    self.hotkey = hotkey
    self.startsRecording = startsRecording
  }

  var body: some View {
    HStack(spacing: Metrics.Spacing.compact) {
      if let message = recording.message {
        ErrorText(message)
      }
      Button(title, action: recording.toggle)
        .buttonStyle(.plain)
        .monospacedDigit()
        .chipSurface()
        .help("Record a new shortcut")
    }
    .onAppear {
      if startsRecording { recording.start() }
    }
    .onDisappear(perform: recording.stop)
  }

  private var title: String {
    if recording.isRecording { return "Press keys, Esc to cancel" }
    return hotkey?.displayString ?? "Record shortcut"
  }
}
