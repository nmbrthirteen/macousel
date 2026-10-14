import SwiftUI

struct OnboardingFeatureRow: View {
  let systemImage: String
  let title: String

  private var tile: RoundedRectangle {
    RoundedRectangle(cornerRadius: OnboardingMetrics.iconTileRadius, style: .continuous)
  }

  var body: some View {
    HStack(spacing: Metrics.Spacing.comfortable + Metrics.Spacing.hairline) {
      Image(systemName: systemImage)
        .font(.system(size: OnboardingMetrics.iconGlyph))
        .foregroundStyle(.secondary)
        .frame(width: OnboardingMetrics.iconTile, height: OnboardingMetrics.iconTile)
        .background(.background, in: tile)
        .overlay { tile.strokeBorder(.separator, lineWidth: Metrics.Size.hairlineStroke) }
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        .accessibilityHidden(true)
      Text(title)
    }
    .accessibilityElement(children: .combine)
  }
}
