import StripCore
import WindowSystem

final class CommandRouter {
  private let state: TilingState
  private let source: any WindowSource
  private let presenter: LayoutPresenter
  private let focus: FocusDriver
  private let reconciler: WindowReconciler

  init(
    state: TilingState, source: any WindowSource, presenter: LayoutPresenter, focus: FocusDriver,
    reconciler: WindowReconciler
  ) {
    self.state = state
    self.source = source
    self.presenter = presenter
    self.focus = focus
    self.reconciler = reconciler
  }

  func perform(_ action: Action) {
    switch action {
    case .sendToNextDisplay: sendFocusedWindowToNextDisplay()
    case .toggleFloating: toggleFloatingOfFocusedWindow()
    case .togglePaused: break
    default: performOnFocusedStrip(action)
    }
  }

  func select(_ window: WindowID) {
    guard let key = state.activeKey(containing: window) else { return }
    state.workspaces[key]?.strip.focus(window)
    state.scrollToFocus(key)
    focus.activate(window, in: key, from: .pointer)
    presenter.relayout()
  }

  private func performOnFocusedStrip(_ action: Action) {
    guard let key = state.focusedKey ?? state.pointerKey, let display = state.display(for: key),
      var strip = state.workspaces[key]?.strip
    else { return }
    let previousFocus = strip.focusedWindow
    let outcome = strip.apply(
      action, viewportWidth: display.visibleFrame.width, config: state.config)

    switch outcome {
    case .ignored:
      return
    case .blockedAtEdge(let side):
      focusNeighbor(of: display, on: side)
      return
    case .applied:
      strip.scrollToFocus(viewportWidth: display.visibleFrame.width, config: state.config)
    case .appliedKeepingScroll:
      break
    }

    state.workspaces[key]?.strip = strip
    present(key, activating: strip.focusedWindow != previousFocus ? strip.focusedWindow : nil)
    reconciler.scheduleSessionSave()
  }

  private func focusNeighbor(of display: Display, on side: HorizontalDirection) {
    let ordered = state.tiledDisplays
    guard let index = ordered.firstIndex(of: display) else { return }
    let neighborIndex = side == .left ? index - 1 : index + 1
    guard ordered.indices.contains(neighborIndex),
      let key = state.activeKey(for: ordered[neighborIndex]),
      let target = state.workspaces[key]?.strip.focusedWindow
    else { return }
    present(key, activating: target)
  }

  private func sendFocusedWindowToNextDisplay() {
    let ordered = state.tiledDisplays
    guard ordered.count > 1, let key = state.focusedKey,
      let window = state.workspaces[key]?.strip.focusedWindow,
      let index = ordered.firstIndex(where: { $0.uuid == key.displayUUID }),
      let destination = state.activeKey(for: ordered[(index + 1) % ordered.count])
    else { return }

    state.workspaces[key]?.strip.remove(window)
    state.workspaces[destination]?.strip.insert(window, config: state.config)
    state.scrollToFocus(key)
    state.scrollToFocus(destination)
    present(destination, activating: window)
  }

  private func toggleFloatingOfFocusedWindow() {
    guard let window = source.focusedWindow() else { return }
    reconciler.toggleFloating(window.id)
    presenter.invalidate(window.id)
    reconciler.reconcile()
    presenter.overlays.refreshTitles()
    presenter.relayout()
  }

  private func present(_ key: Workspace.Key, activating window: WindowID?) {
    if let window {
      focus.activate(window, in: key, from: .command)
    } else {
      state.focusedKey = key
    }
    presenter.overlays.refreshTitles()
    presenter.relayout()
    presenter.overlays.flashMinimap(for: key)
  }
}
