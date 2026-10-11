import AppKit
import SwiftUI

final class OverlayPanel: NSPanel {
  var keyHandler: ((NSEvent) -> Bool)?
  private var isPresented = false

  init<Content: View>(content: Content, interactive: Bool, level: NSWindow.Level = .floating) {
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

    let hostingView = NSHostingView(rootView: content)
    hostingView.sizingOptions = []
    contentView = hostingView
  }

  override var canBecomeKey: Bool { keyHandler != nil }
  override var canBecomeMain: Bool { false }

  func present(fadeDuration: TimeInterval) {
    guard !isPresented else { return }
    isPresented = true
    if !isVisible { alphaValue = fadeDuration > 0 && !Self.reducesMotion ? 0 : 1 }
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
    guard duration > 0, !Self.reducesMotion else {
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
