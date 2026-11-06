import AppKit
import StripCore
import SwiftUI

final class MinimapOverlay {
  var onSelect: ((WindowID) -> Void)?
  var onMove: ((WindowID, DropTarget) -> Void)?

  private let model: MinimapModel
  private let panel: OverlayPanel
  private let hoverTracker = MinimapHoverTracker()
  private let shortcutHold: MinimapShortcutHold

  init(
    shortcutBase: @escaping () -> ShortcutBase = { PreferencesStore().preferences.shortcutBase }
  ) {
    shortcutHold = MinimapShortcutHold(base: shortcutBase)
    let model = MinimapModel(schedule: { delay, action in
      Task {
        try? await Task.sleep(for: delay)
        action()
      }
    })
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
        self?.present()
      } else {
        self?.dismiss(fadeDuration: OverlayTiming.minimapDisappear)
      }
    }
    model.isHoldingShortcut = { [weak self] in self?.shortcutHold.isHeld ?? false }
    shortcutHold.onRelease = { [weak model] in model?.shortcutReleased() }
    hoverTracker.onEnter = { [weak model] in model?.pointerEntered() }
    hoverTracker.onMove = { [weak model] point in model?.pointerMoved(to: point) }
    hoverTracker.onExit = { [weak model] in model?.pointerExited() }
    if let view = panel.contentView { hoverTracker.attach(to: view) }
  }

  func show(_ snapshot: MinimapSnapshot, update: MinimapUpdate, on displayFrame: CGRect) {
    model.show(snapshot, update: update)
    guard model.isShown else { return }
    place(model.snapshot, on: displayFrame)
    present()
  }

  func hide() {
    model.release()
    if !model.isShown { dismiss(fadeDuration: 0) }
  }

  private func present() {
    shortcutHold.start()
    panel.present(fadeDuration: OverlayTiming.minimapAppear)
  }

  private func dismiss(fadeDuration: TimeInterval) {
    shortcutHold.stop()
    panel.dismiss(fadeDuration: fadeDuration)
  }

  private func place(_ snapshot: MinimapSnapshot, on displayFrame: CGRect) {
    let containerWidth = MinimapGeometry.containerWidth(for: snapshot)
    let frame = MinimapPanelFrame.frame(containerWidth: containerWidth, on: displayFrame).axToCocoa
    guard frame != panel.frame else { return }
    panel.setFrame(frame, display: true)
    panel.invalidateShadow()
  }
}
