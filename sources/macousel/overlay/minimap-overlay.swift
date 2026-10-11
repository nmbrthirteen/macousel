import AppKit
import StripCore
import SwiftUI

final class MinimapOverlay {
  var onSelect: ((WindowID) -> Void)?
  var onMove: ((WindowID, DropTarget) -> Void)?

  private let model: MinimapModel
  private let panel: OverlayPanel
  private let hoverTracker = MinimapHoverTracker()

  init() {
    let model = MinimapModel { delay, action in
      Task {
        try? await Task.sleep(for: delay)
        action()
      }
    }
    self.model = model
    model.isInteractive = true
    panel = OverlayPanel(
      content: MinimapView(model: model), interactive: true,
      glassCornerRadius: OverlayRadius.minimapContainer)
    panel.hasShadow = true
    model.onSelect = { [weak self] window in self?.onSelect?(window) }
    model.onMove = { [weak self] window, target in self?.onMove?(window, target) }
    model.onVisibilityChange = { [weak self] isShown in
      if isShown {
        self?.panel.present(fadeDuration: OverlayTiming.minimapAppear)
      } else {
        self?.panel.dismiss(fadeDuration: OverlayTiming.slowFade)
      }
    }
    hoverTracker.onEnter = { [weak model] in model?.pointerEntered() }
    hoverTracker.onExit = { [weak model] in model?.pointerExited() }
    if let view = panel.contentView { hoverTracker.attach(to: view) }
  }

  func show(_ snapshot: MinimapSnapshot, update: MinimapUpdate, on displayFrame: CGRect) {
    model.show(snapshot, update: update)
    place(snapshot, on: displayFrame)
    panel.present(fadeDuration: OverlayTiming.minimapAppear)
  }

  func hide() {
    model.hide()
    panel.dismiss(fadeDuration: 0)
  }

  private func place(_ snapshot: MinimapSnapshot, on displayFrame: CGRect) {
    let containerWidth = MinimapGeometry(snapshot: snapshot).containerWidth
    let frame = MinimapPanelFrame.frame(containerWidth: containerWidth, on: displayFrame).axToCocoa
    guard frame != panel.frame else { return }
    panel.setFrame(frame, display: true)
    panel.invalidateShadow()
  }
}
