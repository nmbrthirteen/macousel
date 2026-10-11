import CoreGraphics

final class WindowRelease {
  private let state: TilingState
  private let source: any WindowSource
  private let environment: any DesktopEnvironment
  private let restorer: WindowRestorer
  private let presenter: LayoutPresenter
  private let scratchpad: Scratchpad

  init(
    state: TilingState, source: any WindowSource, environment: any DesktopEnvironment,
    restorer: WindowRestorer, presenter: LayoutPresenter, scratchpad: Scratchpad
  ) {
    self.state = state
    self.source = source
    self.environment = environment
    self.restorer = restorer
    self.presenter = presenter
    self.scratchpad = scratchpad
  }

  func releaseEverything() {
    presenter.halt()
    scratchpad.reset()
    restorer.restoreSaved(Array(source.windows.values), on: state.displays)
  }

  func restoreEverythingSaved() {
    scratchpad.reset()
    restorer.restoreSaved(Array(source.windows.values), on: environment.displays)
  }

  func forgetSaved() {
    restorer.forgetAll()
  }

  func restoreSaved(_ window: CGWindowID) {
    guard let handle = source.window(window) else { return }
    restorer.restoreSaved([handle], on: environment.displays)
  }
}
