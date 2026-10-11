import SwiftUI

struct SidebarIconTile: View {
  let systemImage: String
  let tint: Color

  var body: some View {
    Image(systemName: systemImage)
      .font(.system(size: Metrics.Size.sidebarGlyph, weight: .medium))
      .foregroundStyle(.white)
      .frame(width: Metrics.Size.sidebarTile, height: Metrics.Size.sidebarTile)
      .background(
        tint.gradient, in: RoundedRectangle(cornerRadius: Metrics.Radius.sidebarTile, style: .continuous)
      )
      .accessibilityHidden(true)
  }
}
