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
  private var transition = OverviewTransition()
  private var capturing: Task<Void, Never>?

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
    switch transition.open() {
    case .update:
      model.show(snapshot)
    case .expand:
      model.show(snapshot)
      expand()
    case .capture(let generation):
      capture(snapshot, on: displayFrame, generation: generation)
    }
  }

  func hide() {
    switch transition.close() {
    case .none:
      return
    case .abandon:
      capturing?.cancel()
      capturing = nil
      shownFrame = nil
      model.previews.release()
    case .collapse(let generation):
      model.endInteraction()
      model.previews.stopLoading()
      backdrop.fade(in: false, duration: transitionDuration(OverlayTiming.overviewCloseResponse))
      // The panel only leaves once every picture sits on its real window again, so the swap
      // back to the real windows happens between two identical frames.
      model.collapse { [weak self] in
        guard let self, self.transition.landed(generation) else { return }
        self.shownFrame = nil
        self.panel.dismiss(fadeDuration: 0)
        self.backdrop.release()
        self.model.previews.release()
      }
    }
  }

  // Nothing shows until the pictures are in, so the first frame can match the desktop exactly.
  private func capture(_ snapshot: OverviewSnapshot, on displayFrame: CGRect, generation: Int) {
    model.prepare(snapshot, on: displayFrame)
    let geometry = OverviewGeometry(snapshot: snapshot, size: displayFrame.size)
    let scale = panel.backingScaleFactor
    let flies = model.animates
    let requests = OverviewPreviews.requests(
      for: geometry, fullSizeOn: flies ? displayFrame : nil, backingScale: scale)
    let desktop =
      flies
      ? DesktopCaptureRequest(
        displayFrame: displayFrame, backingScale: scale, excluding: geometry.cards.map(\.id))
      : nil
    let previews = model.previews
    capturing = Task { [weak self] in
      await previews.load(requests, desktop: desktop, budget: OverlayTiming.overviewCaptureBudget)
      guard let self, self.transition.captured(generation) else { return }
      self.capturing = nil
      self.reveal()
    }
  }

  private func reveal() {
    model.adopt(model.previews.frames)
    backdrop.prepare(desktop: model.previews.desktop)
    panel.present(fadeDuration: 0)
    // Cards must render once at their window frames before the spring starts, or SwiftUI
    // would show them already in place.
    panel.displayIfNeeded()
    expand()
  }

  private func expand() {
    model.expand()
    backdrop.fade(in: true, duration: transitionDuration(OverlayTiming.overviewOpenResponse))
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
