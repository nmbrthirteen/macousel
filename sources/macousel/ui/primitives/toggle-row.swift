import SwiftUI

struct ToggleRow: View {
  let title: String
  @Binding var isOn: Bool
  var detail: String?
  var unavailable: String?

  var body: some View {
    Toggle(isOn: $isOn) {
      RowLabel(title: title, detail: unavailable ?? detail)
    }
    .disabled(unavailable != nil)
  }
}
