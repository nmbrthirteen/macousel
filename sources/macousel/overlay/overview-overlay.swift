import AppKit
import StripCore

final class OverviewOverlay {
  var onSelect: ((WindowID) -> Void)?
  var onKey: ((OverviewKey) -> Void)?
  var onDismiss: (() -> Void)?

  private let model = OverviewModel()
  private let panel: OverlayPanel
  private var shownFrame: CGRect?

  init() {
    panel = OverlayPanel(content: OverviewView(model: model), interactive: true, level: .modalPanel)
    model.onSelect = { [weak self] window in self?.onSelect?(window) }
    model.onDismiss = { [weak self] in self?.onDismiss?() }
    panel.keyHandler = { [weak self] event in self?.handle(event) ?? false }
  }

  func show(_ snapshot: OverviewSnapshot, on displayFrame: CGRect) {
    if snapshot != model.snapshot { model.snapshot = snapshot }
    if displayFrame != shownFrame {
      shownFrame = displayFrame
      panel.setFrame(displayFrame.axToCocoa, display: true)
    }
    panel.present(fadeDuration: OverlayTiming.fade)
  }

  func hide() {
    shownFrame = nil
    panel.dismiss(fadeDuration: OverlayTiming.fade)
  }

  private func handle(_ event: NSEvent) -> Bool {
    guard event.modifierFlags.isDisjoint(with: [.command, .control, .option]) else {
      return false
    }
    if let key = OverviewKeyMap.key(forKeyCode: event.keyCode) { onKey?(key) }
    return true
  }
}
