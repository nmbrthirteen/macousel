import CoreGraphics

@testable import Macousel

@MainActor
final class FakeWindowSource: WindowSource {
  var onEvent: ((WindowSourceEvent) -> Void)?
  private(set) var isStarted = false
  private let environment: FakeDesktopEnvironment
  private var tracked: [CGWindowID: FakeWindow] = [:]
  private var focusedID: CGWindowID?

  init(environment: FakeDesktopEnvironment) {
    self.environment = environment
  }

  var windows: [CGWindowID: any WindowHandle] { tracked }

  func window(_ id: CGWindowID) -> (any WindowHandle)? { tracked[id] }

  func start() {
    isStarted = true
  }

  func stop() {
    isStarted = false
  }

  func focusedWindow() -> (any WindowHandle)? {
    focusedID.flatMap { tracked[$0] }
  }

  func add(_ window: FakeWindow, activating: Bool = true) {
    tracked[window.id] = window
    window.onFocus = { [weak self] window in self?.takeSystemFocus(window) }
    environment.show(window.id)
    if activating { takeSystemFocus(window) }
    onEvent?(.created(window.id))
    if activating { onEvent?(.focused(window.id)) }
  }

  func close(_ window: FakeWindow) {
    tracked[window.id] = nil
    environment.hide(window.id)
    if focusedID == window.id { focusedID = nil }
    onEvent?(.destroyed(window.id))
  }

  func minimize(_ window: FakeWindow) {
    environment.hide(window.id)
    if focusedID == window.id { focusedID = nil }
    onEvent?(.minimized(window.id))
  }

  func restore(_ window: FakeWindow) {
    environment.show(window.id)
    onEvent?(.restored(window.id))
  }

  func focus(_ window: FakeWindow) {
    takeSystemFocus(window)
    onEvent?(.focused(window.id))
  }

  func userMoved(_ window: FakeWindow, to frame: CGRect) {
    window.frame = frame
    onEvent?(.moved(window.id))
  }

  func userResized(_ window: FakeWindow, to frame: CGRect) {
    window.frame = frame
    onEvent?(.resized(window.id))
  }

  private func takeSystemFocus(_ window: FakeWindow) {
    focusedID = window.id
    environment.frontmostProcessID = window.pid
  }
}
