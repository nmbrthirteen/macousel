import CoreGraphics
import StripCore

@testable import Macousel

@MainActor
final class FakeOverlayHost: OverlayHost {
  struct FocusBorder: Equatable {
    var frame: CGRect
    var lineWidth: Double
  }

  struct Dim: Equatable {
    var displayFrames: [CGRect]
    var window: CGWindowID
    var amount: Double
  }

  struct Overview {
    var snapshot: OverviewSnapshot
    var displayFrame: CGRect
  }

  var onTabSelected: ((WindowID) -> Void)?
  var onMinimapSelect: ((WindowID) -> Void)?
  var onMinimapMove: ((WindowID, DropTarget) -> Void)?
  var onOverviewSelect: ((WindowID) -> Void)?
  var onOverviewKey: ((OverviewKey) -> Void)?
  var onOverviewDismiss: (() -> Void)?
  var onOverviewMove: ((WindowID, DropTarget) -> Void)?
  var onOverviewColumnWidth: ((WindowID, Double) -> Void)?
  var onOverviewRowHeight: ((WindowID, Double, VerticalNeighbor) -> Void)?
  var onMinimapShown: ((MinimapSnapshot, MinimapUpdate) -> Void)?
  private(set) var overview: Overview?
  private(set) var dropPreview: CGRect?
  private(set) var dropPreviewHistory: [CGRect?] = []
  private(set) var focusBorder: FocusBorder?
  private(set) var dim: Dim?
  private(set) var minimap: MinimapSnapshot?
  private(set) var minimapUpdate: MinimapUpdate?
  private(set) var tabBars: [TabBarModel] = []

  func showFocusBorder(around frame: CGRect, lineWidth: Double) {
    focusBorder = FocusBorder(frame: frame, lineWidth: lineWidth)
  }

  func hideFocusBorder() {
    focusBorder = nil
  }

  func showDim(on displayFrames: [CGRect], below window: CGWindowID, amount: Double) {
    dim = Dim(displayFrames: displayFrames, window: window, amount: amount)
  }

  func hideDim() {
    dim = nil
  }

  func showMinimap(_ snapshot: MinimapSnapshot, update: MinimapUpdate, on displayFrame: CGRect) {
    minimap = snapshot
    minimapUpdate = update
    onMinimapShown?(snapshot, update)
  }

  func hideMinimap() {
    minimap = nil
    minimapUpdate = nil
  }

  func updateTabBars(_ bars: [TabBarModel]) {
    tabBars = bars
  }

  func showDropPreview(at frame: CGRect) {
    dropPreview = frame
    dropPreviewHistory.append(frame)
  }

  func hideDropPreview() {
    guard dropPreview != nil else { return }
    dropPreview = nil
    dropPreviewHistory.append(nil)
  }

  func showOverview(_ snapshot: OverviewSnapshot, on displayFrame: CGRect) {
    overview = Overview(snapshot: snapshot, displayFrame: displayFrame)
  }

  func hideOverview() {
    overview = nil
  }

  func press(_ key: OverviewKey) {
    onOverviewKey?(key)
  }

  func click(_ window: WindowID) {
    onOverviewSelect?(window)
  }

  func clickMinimap(_ window: WindowID) {
    onMinimapSelect?(window)
  }

  func dropFromMinimap(_ window: WindowID, as target: DropTarget) {
    onMinimapMove?(window, target)
  }

  func clickBackdrop() {
    onOverviewDismiss?()
  }

  func drop(_ window: WindowID, as target: DropTarget) {
    onOverviewMove?(window, target)
  }

  func setColumnWidth(of window: WindowID, to fraction: Double) {
    onOverviewColumnWidth?(window, fraction)
  }

  func setRowHeight(of window: WindowID, to share: Double, borrowingFrom neighbor: VerticalNeighbor) {
    onOverviewRowHeight?(window, share, neighbor)
  }
}
