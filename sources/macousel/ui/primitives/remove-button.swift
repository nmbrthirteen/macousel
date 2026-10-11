import SwiftUI

struct RemoveButton: View {
  let label: String
  let action: () -> Void

  var body: some View {
    Button(label, systemImage: "minus.circle", action: action)
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
      .help(label)
  }
}
