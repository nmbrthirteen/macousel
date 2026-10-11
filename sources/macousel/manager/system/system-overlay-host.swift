import CoreGraphics
import StripCore

final class SystemOverlayHost: OverlayHost {
  private let focusBorder = FocusBorderOverlay()
  private let dim = DimOverlay()
  private let minimap = MinimapOverlay()
  private let tabBars = TabBarOverlay()

  var onTabSelected: ((WindowID) -> Void)? {
    get { tabBars.onSelect }
    set { tabBars.onSelect = newValue }
  }

  func showFocusBorder(around frame: CGRect, lineWidth: Double) {
    focusBorder.show(around: frame, lineWidth: lineWidth)
  }

  func hideFocusBorder() {
    focusBorder.hide()
  }

  func showDim(on displayFrames: [CGRect], below window: CGWindowID, amount: Double) {
    dim.show(on: displayFrames, below: window, amount: amount)
  }

  func hideDim() {
    dim.hide()
  }

  func showMinimap(_ snapshot: MinimapSnapshot, on displayFrame: CGRect) {
    minimap.show(snapshot, on: displayFrame)
  }

  func hideMinimap() {
    minimap.hide()
  }

  func updateTabBars(_ bars: [TabBarModel]) {
    tabBars.update(bars)
  }
}
