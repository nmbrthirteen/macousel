import SwiftUI

extension View {
  func chipSurface() -> some View {
    padding(.horizontal, Metrics.Spacing.regular)
      .padding(.vertical, Metrics.Spacing.tight)
      .background(.quaternary, in: RoundedRectangle(cornerRadius: Metrics.Radius.chip))
  }
}
