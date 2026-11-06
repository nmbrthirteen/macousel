import AppKit
import SwiftUI

final class OverlayPanel: NSPanel {
  var keyHandler: ((NSEvent) -> Bool)?
  private var isPresented = false

  init<Content: View>(
    content: Content, interactive: Bool, level: NSWindow.Level = .floating,
    glassCornerRadius: CGFloat? = nil, backdrop: NSView? = nil
  ) {
    super.init(
      contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered,
      defer: true)
    self.level = level
    collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
    isReleasedWhenClosed = false
    hasShadow = false
    isOpaque = false
    backgroundColor = .clear
    hidesOnDeactivate = false
    ignoresMouseEvents = !interactive
    becomesKeyOnlyIfNeeded = true
    // Ordering in and out must be instant: the overview swaps to and from the real windows
    // between two identical frames.
    animationBehavior = .none

    let hostingView = NSHostingView(rootView: content)
    hostingView.sizingOptions = []
    if let glassCornerRadius, #available(macOS 26, *) {
      let glassView = NSGlassEffectView()
      glassView.cornerRadius = glassCornerRadius
      glassView.contentView = hostingView
      contentView = glassView
    } else if let glassCornerRadius {
      let materialView = NSVisualEffectView()
      materialView.material = .hudWindow
      materialView.state = .active
      materialView.wantsLayer = true
      materialView.layer?.cornerRadius = glassCornerRadius
      materialView.layer?.masksToBounds = true
      hostingView.frame = materialView.bounds
      hostingView.autoresizingMask = [.width, .height]
      materialView.addSubview(hostingView)
      contentView = materialView
    } else if let backdrop {
      let container = NSView()
      for view in [backdrop, hostingView] {
        view.frame = container.bounds
        view.autoresizingMask = [.width, .height]
        container.addSubview(view)
      }
      contentView = container
    } else {
      contentView = hostingView
    }
  }

  override var canBecomeKey: Bool { keyHandler != nil }
  override var canBecomeMain: Bool { false }

  func present(fadeDuration: TimeInterval) {
    guard !isPresented else { return }
    isPresented = true
    if !isVisible { alphaValue = fadeDuration > 0 ? 0 : 1 }
    orderFrontRegardless()
    if keyHandler != nil { makeKey() }
    fade(to: 1, duration: fadeDuration)
  }

  override func sendEvent(_ event: NSEvent) {
    if event.type == .keyDown, keyHandler?(event) == true { return }
    super.sendEvent(event)
  }

  func dismiss(fadeDuration: TimeInterval) {
    guard isPresented else { return }
    isPresented = false
    fade(to: 0, duration: fadeDuration) { [weak self] in
      guard let self, !self.isPresented else { return }
      self.orderOut(nil)
    }
  }

  func fade(
    to alpha: CGFloat, duration: TimeInterval, completion: @escaping @MainActor () -> Void = {}
  ) {
    // Fades stay under Reduce Motion: they are what motion falls back to.
    guard duration > 0 else {
      alphaValue = alpha
      completion()
      return
    }
    NSAnimationContext.runAnimationGroup { context in
      context.duration = duration
      animator().alphaValue = alpha
    } completionHandler: {
      MainActor.assumeIsolated { completion() }
    }
  }

  static var reducesMotion: Bool {
    NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
  }
}
