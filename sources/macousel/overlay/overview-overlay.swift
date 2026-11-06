import AppKit
import StripCore

final class OverviewOverlay {
  var onSelect: ((WindowID) -> Void)?
  var onKey: ((OverviewKey) -> Void)?
  var onDismiss: (() -> Void)?
  var onMove: ((WindowID, DropTarget) -> Void)?
  var onColumnWidth: ((WindowID, Double) -> Void)?
  var onRowHeight: ((WindowID, Double, VerticalNeighbor) -> Void)?

  private let model: OverviewModel
  private let panel: OverlayPanel
  private let backdrop = OverviewBackdrop()
  private var shownFrame: CGRect?
  private var isOpen = false
  private var closings = 0

  init(capture: any WindowCapture) {
    model = OverviewModel(previews: OverviewPreviews(capture: capture))
    panel = OverlayPanel(
      content: OverviewView(model: model), interactive: true, level: .modalPanel,
      backdrop: backdrop)
    panel.appearance = NSAppearance(named: .darkAqua)
    model.onSelect = { [weak self] window in self?.onSelect?(window) }
    model.onDismiss = { [weak self] in self?.onDismiss?() }
    model.onMove = { [weak self] window, target in self?.onMove?(window, target) }
    model.onColumnWidth = { [weak self] window, fraction in
      self?.onColumnWidth?(window, fraction)
    }
    model.onRowHeight = { [weak self] window, share, neighbor in
      self?.onRowHeight?(window, share, neighbor)
    }
    panel.keyHandler = { [weak self] event in self?.handle(event) ?? false }
  }

  func show(_ snapshot: OverviewSnapshot, on displayFrame: CGRect) {
    if displayFrame != shownFrame {
      shownFrame = displayFrame
      panel.setFrame(displayFrame.axToCocoa, display: true)
    }
    guard !isOpen else {
      model.show(snapshot)
      return
    }
    isOpen = true
    model.prepare(snapshot, on: displayFrame)
    panel.present(fadeDuration: 0)
    // Cards must render once at their window frames before the spring starts, or SwiftUI
    // would show them already in place.
    panel.displayIfNeeded()
    model.previews.load(
      OverviewPreviews.requests(
        for: OverviewGeometry(snapshot: snapshot, size: displayFrame.size),
        backingScale: panel.backingScaleFactor))
    model.expand()
    backdrop.fade(in: true, duration: transitionDuration(OverlayTiming.overviewOpenResponse))
  }

  func hide() {
    guard isOpen else { return }
    isOpen = false
    closings += 1
    let closing = closings
    model.endInteraction()
    model.previews.stopLoading()
    backdrop.fade(in: false, duration: transitionDuration(OverlayTiming.overviewCloseResponse))
    model.collapse { [weak self] in
      guard let self, !self.isOpen, self.closings == closing else { return }
      self.shownFrame = nil
      self.panel.dismiss(fadeDuration: 0)
      self.model.previews.release()
    }
  }

  private func transitionDuration(_ response: TimeInterval) -> TimeInterval {
    model.animates ? response : OverlayTiming.fade
  }

  private func handle(_ event: NSEvent) -> Bool {
    guard event.modifierFlags.isDisjoint(with: [.command, .control, .option]) else {
      return false
    }
    let isShifted = event.modifierFlags.contains(.shift)
    if let key = OverviewKeyMap.key(forKeyCode: event.keyCode, shifted: isShifted) { onKey?(key) }
    return true
  }
}
