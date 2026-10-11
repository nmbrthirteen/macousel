import AppKit
import SwiftUI

final class OnboardingWindowController {
  private let store: PreferencesStore
  private var window: NSWindow?

  init(store: PreferencesStore) {
    self.store = store
  }

  func showIfNeeded() {
    guard !store.preferences.hasCompletedOnboarding else { return }
    show()
  }

  func show() {
    let window = window ?? makeWindow()
    self.window = window
    NSApp.activate()
    window.makeKeyAndOrderFront(nil)
  }

  private func finish() {
    store.preferences.hasCompletedOnboarding = true
    window?.close()
    window = nil
  }

  private func makeWindow() -> NSWindow {
    let flow = OnboardingFlow { [weak self] in self?.finish() }
    let size = NSSize(
      width: Metrics.Size.onboardingWidth, height: Metrics.Size.onboardingHeight)
    let window = NSWindow(
      contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled, .closable],
      backing: .buffered, defer: false)
    let content = NSHostingView(rootView: OnboardingView(store: store, flow: flow))
    content.sizingOptions = []
    window.contentView = content
    window.setContentSize(size)
    window.title = "Welcome to Macousel"
    window.isReleasedWhenClosed = false
    window.center()
    return window
  }
}
