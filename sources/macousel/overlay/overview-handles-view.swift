import StripCore
import SwiftUI

struct OverviewHandlesView: View {
  let areas: OverviewHitAreas
  let activeColumnWindow: WindowID?
  let activeDivider: WindowID?

  var body: some View {
    ForEach(areas.edges, id: \.window) { edge in
      OverviewGripView(axis: .column, rect: edge.rect, isActive: edge.window == activeColumnWindow)
    }
    ForEach(areas.dividers, id: \.upper) { divider in
      OverviewGripView(axis: .row, rect: divider.rect, isActive: divider.upper == activeDivider)
    }
  }
}
