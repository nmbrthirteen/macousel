import SwiftUI

struct ToggleRow: View {
  let title: String
  @Binding var isOn: Bool
  var caption: String?

  var body: some View {
    CaptionedRow(caption: caption) {
      Toggle(title, isOn: $isOn)
    }
  }
}
