import AppKit
import SwiftUI

final class OnboardingWindowController {
  private let store: PreferencesStore
  private var window: NSWindow?
  private var closeObserver: (any NSObjectProtocol)?

  init(store: PreferencesStore) {
    self.store = store
  }

  @discardableResult
  func showIfNeeded() -> Bool {
    guard !store.preferences.hasCompletedOnboarding else { return false }
    show()
    return true
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
  }

  // A closed window that is not released keeps its SwiftUI views alive, and the practice
  // step's key tap with them. Dropping the content runs their onDisappear.
  private func windowWillClose() {
    if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
    closeObserver = nil
    window?.contentView = nil
    window = nil
  }

  private func makeWindow() -> NSWindow {
    let flow = OnboardingFlow { [weak self] in self?.finish() }
    let window = NSWindow.titleless(
      title: "Welcome to Macousel",
      size: NSSize(width: OnboardingMetrics.width, height: OnboardingMetrics.height),
      rootView: OnboardingView(store: store, flow: flow))
    closeObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification, object: window, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated { self?.windowWillClose() }
    }
    return window
  }
}
