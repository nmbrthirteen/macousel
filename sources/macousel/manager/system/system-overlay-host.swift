import CoreGraphics
import StripCore

final class SystemOverlayHost: OverlayHost {
  private var focusBorder: FocusBorderOverlay?
  private var dim: DimOverlay?
  private var minimap: MinimapOverlay?
  private var tabBars: TabBarOverlay?

  var onTabSelected: ((WindowID) -> Void)?

  func showFocusBorder(around frame: CGRect, lineWidth: Double) {
    let overlay = focusBorder ?? FocusBorderOverlay()
    focusBorder = overlay
    overlay.show(around: frame, lineWidth: lineWidth)
  }

  func hideFocusBorder() {
    focusBorder?.hide()
  }

  func showDim(on displayFrames: [CGRect], below window: CGWindowID, amount: Double) {
    let overlay = dim ?? DimOverlay()
    dim = overlay
    overlay.show(on: displayFrames, below: window, amount: amount)
  }

  func hideDim() {
    dim?.hide()
  }

  func showMinimap(_ snapshot: MinimapSnapshot, on displayFrame: CGRect) {
    let overlay = minimap ?? MinimapOverlay()
    minimap = overlay
    overlay.show(snapshot, on: displayFrame)
  }

  func hideMinimap() {
    minimap?.hide()
  }

  func updateTabBars(_ bars: [TabBarModel]) {
    guard let overlay = tabBars ?? (bars.isEmpty ? nil : makeTabBars()) else { return }
    tabBars = overlay
    overlay.update(bars)
  }

  private func makeTabBars() -> TabBarOverlay {
    let overlay = TabBarOverlay()
    overlay.onSelect = { [weak self] window in self?.onTabSelected?(window) }
    return overlay
  }
}
