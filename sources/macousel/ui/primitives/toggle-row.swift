import SwiftUI

struct ToggleRow: View {
  let title: String
  @Binding var isOn: Bool
  var caption: String?

  var body: some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.tight) {
      Toggle(title, isOn: $isOn)
      if let caption {
        CaptionText(caption)
      }
    }
  }
}
