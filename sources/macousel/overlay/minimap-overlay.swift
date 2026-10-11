import AppKit
import SwiftUI

final class MinimapOverlay {
  private static let panelSize = CGSize(
    width: Metrics.Minimap.maximumWidth + 2 * Metrics.Minimap.panelMargin,
    height: Metrics.Minimap.height + 2 * Metrics.Minimap.panelMargin)

  private let model = MinimapModel()
  private let panel: OverlayPanel
  private var hideTask: Task<Void, Never>?
  private var lastDisplayFrame: CGRect?

  init() {
    panel = OverlayPanel(content: MinimapView(model: model), interactive: false)
  }

  func show(_ snapshot: MinimapSnapshot, update: MinimapUpdate, on displayFrame: CGRect) {
    hideTask?.cancel()
    model.apply(snapshot, update: model.isShown ? update : .immediate)
    place(on: displayFrame)
    panel.present(fadeDuration: 0)
    model.isShown = true
    hideTask = Task { [weak self] in
      try? await Task.sleep(for: OverlayTiming.minimapLinger)
      guard !Task.isCancelled else { return }
      self?.model.isShown = false
      try? await Task.sleep(for: .seconds(OverlayTiming.slowFade))
      guard !Task.isCancelled else { return }
      self?.panel.dismiss(fadeDuration: 0)
    }
  }

  func hide() {
    hideTask?.cancel()
    hideTask = nil
    model.isShown = false
    panel.dismiss(fadeDuration: 0)
  }

  private func place(on displayFrame: CGRect) {
    guard displayFrame != lastDisplayFrame else { return }
    lastDisplayFrame = displayFrame
    let size = Self.panelSize
    let capsuleBottom = displayFrame.maxY - Metrics.Spacing.spacious
    let axFrame = CGRect(
      x: displayFrame.midX - size.width / 2,
      y: capsuleBottom + Metrics.Minimap.panelMargin - size.height,
      width: size.width, height: size.height)
    panel.setFrame(axFrame.axToCocoa, display: true)
  }
}
