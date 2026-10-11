import SwiftUI
import WindowSystem

struct AppShortcutChip: View {
  let recording: ShortcutRecording
  let hotkey: Hotkey?
  let appName: String

  var body: some View {
    Button(title, action: recording.toggle)
      .buttonStyle(.plain)
      .monospacedDigit()
      .chipSurface()
      .help("Record a new shortcut")
      .accessibilityLabel("Shortcut for \(appName)")
      .accessibilityValue(hotkey?.displayString ?? "None")
      .accessibilityHint("Records a new shortcut")
  }

  private var title: String {
    if recording.isRecording { return ShortcutRecording.prompt }
    return hotkey?.displayString ?? "Record shortcut"
  }
}
