import SwiftUI

struct ShortcutAddButton: View {
  let recording: ShortcutRecording
  let label: String

  var body: some View {
    if recording.isRecording {
      Button(ShortcutRecording.prompt, action: recording.toggle)
        .controlSize(.small)
    } else {
      Button(label, systemImage: "plus.circle", action: recording.toggle)
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .help("Add shortcut")
    }
  }
}
