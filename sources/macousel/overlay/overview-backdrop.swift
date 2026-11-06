import AppKit

final class OverviewBackdrop: NSView {
  private let blur = NSVisualEffectView()

  init() {
    super.init(frame: .zero)
    wantsLayer = true
    alphaValue = 0
    blur.material = .fullScreenUI
    blur.blendingMode = .behindWindow
    blur.state = .active
    blur.appearance = NSAppearance(named: .darkAqua)
    blur.autoresizingMask = [.width, .height]
    addSubview(blur)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  func fade(in isShown: Bool, duration: TimeInterval) {
    if isShown { matchTransparencySetting() }
    NSAnimationContext.runAnimationGroup { context in
      context.duration = duration
      context.timingFunction = CAMediaTimingFunction(name: .easeOut)
      animator().alphaValue = isShown ? 1 : 0
    }
  }

  private func matchTransparencySetting() {
    let isSolid = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    blur.frame = bounds
    blur.isHidden = isSolid
    let solid = NSColor.black.withAlphaComponent(Metrics.Opacity.overviewSolidBackdrop)
    layer?.backgroundColor = isSolid ? solid.cgColor : nil
  }
}
