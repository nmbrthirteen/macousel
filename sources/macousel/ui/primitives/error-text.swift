import SwiftUI

struct ErrorText: View {
  let message: String

  init(_ message: String) {
    self.message = message
  }

  var body: some View {
    Label(message, systemImage: "exclamationmark.triangle.fill")
      .font(.callout)
      .foregroundStyle(.red)
      .fixedSize(horizontal: false, vertical: true)
  }
}
