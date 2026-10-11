import AppKit
import StripCore

final class OverviewOverlay {
  var onSelect: ((WindowID) -> Void)?
  var onKey: ((OverviewKey) -> Void)?
  var onDismiss: (() -> Void)?
  var onMove: ((WindowID, DropTarget) -> Void)?
  var onColumnWidth: ((WindowID, Double) -> Void)?
  var onRowHeight: ((WindowID, Double, VerticalNeighbor) -> Void)?

  private let model = OverviewModel()
  private let panel: OverlayPanel
  private var shownFrame: CGRect?

  init() {
    panel = OverlayPanel(content: OverviewView(model: model), interactive: true, level: .modalPanel)
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
    model.show(snapshot)
    if displayFrame != shownFrame {
      shownFrame = displayFrame
      panel.setFrame(displayFrame.axToCocoa, display: true)
    }
    panel.present(fadeDuration: OverlayTiming.fade)
  }

  func hide() {
    shownFrame = nil
    model.endInteraction()
    panel.dismiss(fadeDuration: OverlayTiming.fade)
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
