import AppKit

final class FocusBorderOverlay {
  private let model = FocusBorderModel()
  private let panel: OverlayPanel
  private var lastFrame: CGRect?
  private var lastLineWidth: Double?

  init() {
    panel = OverlayPanel(content: FocusBorderView(model: model), interactive: false)
  }

  func show(around frame: CGRect, lineWidth: Double) {
    if frame != lastFrame || lineWidth != lastLineWidth {
      lastFrame = frame
      lastLineWidth = lineWidth
      model.lineWidth = lineWidth
      let cocoaFrame = frame.insetBy(dx: -lineWidth, dy: -lineWidth).axToCocoa
      if panel.frame.size == cocoaFrame.size {
        panel.setFrameOrigin(cocoaFrame.origin)
      } else {
        panel.setFrame(cocoaFrame, display: true)
      }
    }
    panel.present(fadeDuration: OverlayTiming.fade)
  }

  func hide() {
    lastFrame = nil
    lastLineWidth = nil
    panel.dismiss(fadeDuration: OverlayTiming.fade)
  }
}
