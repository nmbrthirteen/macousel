import CoreGraphics
import StripCore

protocol OverlayHost: AnyObject {
  var onTabSelected: ((WindowID) -> Void)? { get set }
  var onOverviewSelect: ((WindowID) -> Void)? { get set }
  var onOverviewKey: ((OverviewKey) -> Void)? { get set }
  var onOverviewDismiss: (() -> Void)? { get set }
  var onOverviewMove: ((WindowID, DropTarget) -> Void)? { get set }
  var onOverviewColumnWidth: ((WindowID, Double) -> Void)? { get set }
  var onOverviewRowHeight: ((WindowID, Double, VerticalNeighbor) -> Void)? { get set }
  func showFocusBorder(around frame: CGRect, lineWidth: Double)
  func hideFocusBorder()
  func showDim(on displayFrames: [CGRect], below window: CGWindowID, amount: Double)
  func hideDim()
  func showMinimap(_ snapshot: MinimapSnapshot, update: MinimapUpdate, on displayFrame: CGRect)
  func hideMinimap()
  func updateTabBars(_ bars: [TabBarModel])
  func showDropPreview(at frame: CGRect)
  func hideDropPreview()
  func showOverview(_ snapshot: OverviewSnapshot, on displayFrame: CGRect)
  func hideOverview()
}
