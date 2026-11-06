import SwiftUI

// A grouped form draws a label's second text as the row's secondary description line.
struct RowLabel: View {
  let title: String
  var detail: String?

  var body: some View {
    Text(title)
    if let detail {
      Text(detail)
    }
  }
}
