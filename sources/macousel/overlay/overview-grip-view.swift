import SwiftUI

struct OverviewGripView: View {
  enum Axis {
    case column
    case row
  }

  let axis: Axis
  let rect: CGRect
  let isActive: Bool
  @State private var isHovering = false

  private var style: AnyShapeStyle {
    if isActive { return AnyShapeStyle(Color.accentColor) }
    return isHovering ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tertiary)
  }

  private var gripSize: CGSize {
    axis == .column
      ? CGSize(width: Metrics.Overview.gripThickness, height: Metrics.Overview.gripLength)
      : CGSize(width: Metrics.Overview.gripLength, height: Metrics.Overview.gripThickness)
  }

  var body: some View {
    Color.clear
      .frame(width: rect.width, height: rect.height)
      .overlay {
        Capsule()
          .fill(style)
          .frame(width: gripSize.width, height: gripSize.height)
      }
      .contentShape(Rectangle())
      .resizePointer(axis == .column ? .horizontal : .vertical)
      .onHover { isHovering = $0 }
      .offset(x: rect.minX, y: rect.minY)
  }
}
