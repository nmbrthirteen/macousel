import AppKit
import SwiftUI

final class MinimapOverlay {
  private let model = MinimapModel()
  private let panel: OverlayPanel
  private var hideTask: Task<Void, Never>?

  init() {
    panel = OverlayPanel(
      content: MinimapView(model: model), interactive: false,
      glassCornerRadius: Metrics.Minimap.containerRadius)
    panel.hasShadow = true
  }

  func show(_ snapshot: MinimapSnapshot, update: MinimapUpdate, on displayFrame: CGRect) {
    hideTask?.cancel()
    model.apply(snapshot, update: model.isShown ? update : .immediate)
    place(snapshot, on: displayFrame)
    panel.present(fadeDuration: OverlayTiming.minimapAppear)
    model.isShown = true
    hideTask = Task { [weak self] in
      try? await Task.sleep(for: OverlayTiming.minimapLinger)
      guard !Task.isCancelled else { return }
      self?.model.isShown = false
      self?.panel.dismiss(fadeDuration: OverlayTiming.slowFade)
    }
  }

  func hide() {
    hideTask?.cancel()
    hideTask = nil
    model.isShown = false
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
