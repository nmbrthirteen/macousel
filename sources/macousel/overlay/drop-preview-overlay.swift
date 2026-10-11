import AppKit
import SwiftUI

final class DropPreviewOverlay {
  private let model = DropPreviewModel()
  private let panel: OverlayPanel
  private var isShown = false
  private var shownArea: CGRect?

  init() {
    panel = OverlayPanel(content: DropPreviewView(model: model), interactive: false)
  }

  func show(at frame: CGRect) {
    let area = Self.screenArea
    if area != shownArea {
      shownArea = area
      panel.setFrame(area.axToCocoa, display: true)
    }
    let local = DropPreviewPlacement(area: area).localFrame(of: frame)
    guard isShown else {
      appear(at: local)
      return
    }
    guard model.frame != local else { return }
    if OverlayPanel.reducesMotion {
      jump(to: local)
    } else {
      withAnimation(
        .spring(
          response: OverlayTiming.dropPreviewResponse,
          dampingFraction: OverlayTiming.springDamping)
      ) { model.frame = local }
    }
  }

  func hide() {
    guard isShown else { return }
    isShown = false
    panel.dismiss(fadeDuration: OverlayTiming.dropPreviewFade)
  }

  private func appear(at local: CGRect) {
    jump(to: local)
    isShown = true
    panel.present(fadeDuration: OverlayTiming.dropPreviewFade)
  }

  private func jump(to local: CGRect) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) { model.frame = local }
  }

  private static var screenArea: CGRect {
    NSScreen.screens.map(\.frame).reduce(CGRect.null) { $0.union($1) }.axToCocoa
  }
}
