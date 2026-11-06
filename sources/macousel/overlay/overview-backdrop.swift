import AppKit

final class OverviewBackdrop: NSView {
  private let desktop = NSImageView()
  private let cover = NSView()
  private let blur = NSVisualEffectView()

  init() {
    super.init(frame: .zero)
    desktop.imageScaling = .scaleAxesIndependently
    desktop.isHidden = true
    cover.wantsLayer = true
    cover.alphaValue = 0
    blur.material = .fullScreenUI
    blur.state = .active
    for (view, parent) in [(desktop, self), (cover, self), (blur, cover)] {
      view.frame = parent.bounds
      view.autoresizingMask = [.width, .height]
      parent.addSubview(view)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  // With a picture of the desktop the blur works on that picture inside the panel. Without one
  // it falls back to blurring the real windows behind the panel.
  func prepare(desktop picture: CGImage?) {
    desktop.image = picture.map { NSImage(cgImage: $0, size: bounds.size) }
    desktop.isHidden = picture == nil
    blur.blendingMode = picture == nil ? .behindWindow : .withinWindow
    let isSolid = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    blur.isHidden = isSolid
    effectiveAppearance.performAsCurrentDrawingAppearance {
      cover.layer?.backgroundColor = isSolid ? NSColor.windowBackgroundColor.cgColor : nil
    }
    cover.alphaValue = 0
  }

  func fade(in isShown: Bool, duration: TimeInterval) {
    NSAnimationContext.runAnimationGroup { context in
      context.duration = duration
      context.timingFunction = CAMediaTimingFunction(name: .easeOut)
      cover.animator().alphaValue = isShown ? 1 : 0
    }
  }

  func release() {
    desktop.image = nil
    desktop.isHidden = true
  }
}
