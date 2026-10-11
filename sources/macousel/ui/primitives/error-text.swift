import SwiftUI

struct ErrorText: View {
  let message: String

  init(_ message: String) {
    self.message = message
  }

  var body: some View {
    Text(message)
      .font(.callout)
      .foregroundStyle(.red)
  }
}
