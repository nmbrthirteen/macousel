import SwiftUI

struct CaptionedRow<Content: View>: View {
  var caption: String?
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.tight) {
      content
      if let caption {
        CaptionText(caption)
      }
    }
  }
}
