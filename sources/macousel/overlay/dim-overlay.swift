import AppKit
import SwiftUI

final class DimOverlay {
  private var panels: [OverlayPanel] = []
  private var shownFrames: [CGRect] = []
  private var shownAmount: Double?
  private var isShown = false

  init() {}

  func show(on displayFrames: [CGRect], below windowID: CGWindowID, amount: Double) {
    isShown = true
    resizePool(to: displayFrames.count)
    let amountChanged = amount != shownAmount
    for (index, frame) in displayFrames.enumerated() {
      let panel = panels[index]
      if index >= shownFrames.count || shownFrames[index] != frame {
        panel.setFrame(frame.axToCocoa, display: true)
      }
      let wasVisible = panel.isVisible
      if !wasVisible { panel.alphaValue = 0 }
      panel.order(.below, relativeTo: Int(windowID))
      if amountChanged || !wasVisible { panel.fade(to: amount, duration: OverlayTiming.fade) }
    }
    shownFrames = displayFrames
    shownAmount = amount
  }

  func hide() {
    guard isShown else { return }
    isShown = false
    shownAmount = nil
    shownFrames = []
    for panel in panels {
      panel.fade(to: 0, duration: OverlayTiming.fade) { [weak self, weak panel] in
        guard let self, !self.isShown else { return }
        panel?.orderOut(nil)
      }
    }
  }

  private func resizePool(to count: Int) {
    while panels.count < count {
      panels.append(OverlayPanel(content: Color.black, interactive: false, level: .normal))
    }
    while panels.count > count {
      panels.removeLast().orderOut(nil)
    }
  }
}
