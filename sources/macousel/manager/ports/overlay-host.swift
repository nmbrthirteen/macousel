import CoreGraphics
import StripCore

protocol OverlayHost: AnyObject {
  var onTabSelected: ((WindowID) -> Void)? { get set }
  var onOverviewSelect: ((WindowID) -> Void)? { get set }
  var onOverviewKey: ((OverviewKey) -> Void)? { get set }
  var onOverviewDismiss: (() -> Void)? { get set }
  func showFocusBorder(around frame: CGRect, lineWidth: Double)
  func hideFocusBorder()
  func showDim(on displayFrames: [CGRect], below window: CGWindowID, amount: Double)
  func hideDim()
  func showMinimap(_ snapshot: MinimapSnapshot, on displayFrame: CGRect)
  func hideMinimap()
  func updateTabBars(_ bars: [TabBarModel])
  func showOverview(_ snapshot: OverviewSnapshot, on displayFrame: CGRect)
  func hideOverview()
}
