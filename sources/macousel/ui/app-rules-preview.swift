import StripCore
import SwiftUI

struct AppRulesPreview: View {
  let config: LayoutConfig
  let keepsFloatingOnTop: Bool

  var body: some View {
    PreviewSection(description: PreviewDescription.floating(keepsOnTop: keepsFloatingOnTop)) {
      StripPreview(
        scenario: PreviewScenarios.rules().withLeadingColumns(
          PreviewMetrics.Sample.rulesLeadingColumns,
          width: .fraction(PreviewMetrics.Sample.rulesColumnWidth)),
        config: config,
        decoration: StripPreviewDecoration(
          floatingCard: FloatingPreviewCard(
            unitFrame: PreviewMetrics.Cards.rulesFloating, isAboveTiled: keepsFloatingOnTop)))
    }
  }
}
