import CoreGraphics
import StripCore

final class SystemOverlayHost: OverlayHost {
  private var focusBorder: FocusBorderOverlay?
  private var dim: DimOverlay?
  private var minimap: MinimapOverlay?
  private var tabBars: TabBarOverlay?
  private var overview: OverviewOverlay?

  var onTabSelected: ((WindowID) -> Void)?
  var onOverviewSelect: ((WindowID) -> Void)?
  var onOverviewKey: ((OverviewKey) -> Void)?
  var onOverviewDismiss: (() -> Void)?

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

  func showOverview(_ snapshot: OverviewSnapshot, on displayFrame: CGRect) {
    let overlay = overview ?? makeOverview()
    overview = overlay
    overlay.show(snapshot, on: displayFrame)
  }

  func hideOverview() {
    overview?.hide()
  }

  private func makeOverview() -> OverviewOverlay {
    let overlay = OverviewOverlay()
    overlay.onSelect = { [weak self] window in self?.onOverviewSelect?(window) }
    overlay.onKey = { [weak self] key in self?.onOverviewKey?(key) }
    overlay.onDismiss = { [weak self] in self?.onOverviewDismiss?() }
    return overlay
  }

  private func makeTabBars() -> TabBarOverlay {
    let overlay = TabBarOverlay()
    overlay.onSelect = { [weak self] window in self?.onTabSelected?(window) }
    return overlay
  }
}
