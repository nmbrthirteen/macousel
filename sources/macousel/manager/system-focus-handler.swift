import StripCore

final class SystemFocusHandler {
  private let state: TilingState
  private let presenter: LayoutPresenter
  private let focus: FocusDriver
  private let floating: FloatingWindowKeeper

  init(
    state: TilingState, presenter: LayoutPresenter, focus: FocusDriver,
    floating: FloatingWindowKeeper
  ) {
    self.state = state
    self.presenter = presenter
    self.focus = focus
    self.floating = floating
  }

  func changed(to window: WindowID) {
    guard !focus.isEchoOfEarlierActivation(window) else { return }
    focus.observed(window)
    presenter.overlays.restackDim()
    let key = state.activeKey(containing: window)
    state.focusedKey = key
    if let key, state.workspaces[key]?.strip.focusedWindow != window {
      state.workspaces[key]?.strip.focus(window)
      state.scrollToFocus(key)
      presenter.relayout()
    } else {
      presenter.render()
    }
    floating.focusObserved(window)
  }
}
