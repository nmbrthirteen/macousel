import CoreGraphics
import StripCore

enum OverviewInteraction {
  enum Press {
    case card(WindowID)
    case edge(OverviewHitAreas.Edge)
    case divider(OverviewHitAreas.Divider)
    case backdrop
  }

  struct CardDrag {
    var window: WindowID
    var grab: CGVector
    var size: CGSize
    var target: DropTarget
  }

  struct ColumnResize {
    var window: WindowID
    var column: Int
    var origin: CGPoint
    var resize: OverviewColumnResize
    var current: OverviewColumnResize.Result

    var hasChanged: Bool { abs(current.width - resize.startWidth) > Metrics.Overview.widthNoise }
  }

  struct RowResize {
    var divider: OverviewHitAreas.Divider
    var origin: CGPoint
    var resize: OverviewRowResize
    var upperShare: Double
  }

  case idle
  case pressed(Press, origin: CGPoint)
  case movingCard(CardDrag)
  case resizingColumn(ColumnResize)
  case resizingRows(RowResize)
}
