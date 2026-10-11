import StripCore
import WindowSystem

final class CommandRouter {
  private let state: TilingState
  private let source: any WindowSource
  private let presenter: LayoutPresenter
  private let focus: FocusDriver
  private let reconciler: WindowReconciler
  private let scratchpad: Scratchpad
  private let overview: OverviewController
  private let log = CommandLog()

  init(
    state: TilingState, source: any WindowSource, presenter: LayoutPresenter, focus: FocusDriver,
    reconciler: WindowReconciler, scratchpad: Scratchpad, overview: OverviewController
  ) {
    self.state = state
    self.source = source
    self.presenter = presenter
    self.focus = focus
    self.reconciler = reconciler
    self.scratchpad = scratchpad
    self.overview = overview
    overview.onChoose = { [weak self] window in self?.reveal(window) }
    overview.onEdited = { [weak self] in
      self?.presenter.relayout()
      self?.reconciler.scheduleSessionSave()
    }
  }

  var isOverviewOpen: Bool { overview.isOpen }

  func closeOverview() {
    overview.close()
  }

  func dropped(_ action: Action, because reason: DroppedCommandReason) {
    log.dropped(action, because: reason)
  }

  func perform(_ action: Action) {
    if action != .toggleOverview {
      if overview.isOpen { log.closedOverview(before: action) }
      overview.close()
    }
    switch action {
    case .sendToNextDisplay: sendFocusedWindowToNextDisplay()
    case .toggleFloating: toggleFloatingOfFocusedWindow()
    case .toggleOverview: overview.toggle()
    case .sendToScratchpad: sendFocusedWindowToScratchpad()
    case .toggleScratchpad: scratchpad.toggle()
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
    else {
      log.dropped(action, because: .noActiveWorkspace)
      return
    }
    let previousFocus = strip.focusedWindow
    let before = strip
    let outcome = strip.apply(
      action, viewportWidth: display.visibleFrame.width, config: state.config)
    log.performed(action, outcome: outcome, before: before, after: strip)

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

  private func sendFocusedWindowToScratchpad() {
    guard let key = state.focusedKey ?? state.pointerKey,
      let window = state.workspaces[key]?.strip.focusedWindow
    else { return }
    let displaced = scratchpad.window
    guard scratchpad.send(window.rawValue, from: key) else { return }
    for sent in [window.rawValue, displaced].compactMap({ $0 }) { presenter.invalidate(sent) }
    reconciler.reconcile(adoptingFocus: false, refreshingTabTitles: false) { [weak self] in
      self?.present(key, activating: self?.state.workspaces[key]?.strip.focusedWindow)
    }
  }

  func reveal(_ window: WindowID) {
    guard let key = state.activeKey(containing: window) else { return }
    state.workspaces[key]?.strip.focus(window)
    state.scrollToFocus(key)
    present(key, activating: window)
    reconciler.scheduleSessionSave()
  }

  func moveFromMinimap(_ window: WindowID, to target: DropTarget) {
    guard let key = state.activeKey(containing: window),
      OverviewEdits(state: state).move(window, to: target, in: key)
    else { return }
    present(key, activating: nil)
    reconciler.scheduleSessionSave()
  }

  private func toggleFloatingOfFocusedWindow() {
    guard let window = source.focusedWindow() else { return }
    reconciler.toggleFloating(window.id)
    presenter.invalidate(window.id)
    reconciler.reconcile { [weak self] in
      guard let self else { return }
      presenter.overlays.refreshTitles(using: reconciler.probedTitles)
      presenter.relayout()
    }
  }

  private func present(_ key: Workspace.Key, activating window: WindowID?) {
    if let window {
      focus.activate(window, in: key, from: .command)
    } else {
      state.focusedKey = key
    }
    presenter.overlays.readMissingTitles()
    presenter.relayout()
    presenter.overlays.flashMinimap(for: key, update: .animated)
  }
}
