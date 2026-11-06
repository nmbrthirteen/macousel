import SwiftUI

// Reads the hovered window on its own, so hovering redraws the label without the tiles.
struct MinimapLabelView: View {
  let model: MinimapModel

  private var text: String {
    let window = model.hoveredWindow ?? model.arrangement.focusedWindow
    let text = MinimapLabel.text(for: window, in: model.arrangement) { bundleIdentifier in
      AppIdentity.cached(bundleIdentifier: bundleIdentifier, iconSide: Metrics.Minimap.iconSide)
        .name
    }
    return text ?? ""
  }

  var body: some View {
    Text(text)
      .font(.overlay(.small, weight: .semibold))
      .foregroundStyle(.primary)
      .lineLimit(1)
      .truncationMode(.middle)
      .frame(maxWidth: .infinity)
  }
}
