import CoreGraphics
import WindowSystem

final class DisplayFollowsPointer {
  private static let restDuration = Duration.milliseconds(120)

  var isSuppressed: () -> Bool = { false }

  private let state: TilingState
  private let presenter: LayoutPresenter
  private let focus: FocusDriver
  private let store: PreferencesStore
  private let pointer: any PointerDevice
  private var observedKey: Workspace.Key?
  private var restWait: Task<Void, Never>?

  init(
    state: TilingState, presenter: LayoutPresenter, focus: FocusDriver, store: PreferencesStore,
    pointer: any PointerDevice
  ) {
    self.state = state
    self.presenter = presenter
    self.focus = focus
    self.store = store
    self.pointer = pointer
  }

  func pointerMoved(to point: CGPoint) {
    guard store.preferences.displayFollowsPointer else {
      stop()
      return
    }
    let key = state.activeKey(at: point)
    guard key != observedKey else { return }
    restWait?.cancel()
    observedKey = key
    guard let key else { return }
    restWait = Task { [weak self] in
      try? await Task.sleep(for: Self.restDuration)
      if Task.isCancelled { return }
      self?.activate(key)
    }
  }

  func stop() {
    restWait?.cancel()
    restWait = nil
    observedKey = nil
  }

  private func activate(_ key: Workspace.Key) {
    guard store.preferences.displayFollowsPointer, key != state.focusedKey,
      state.activeKeys.contains(key), !pointer.isPrimaryButtonDown, !isSuppressed(),
      presenter.isSettled
    else { return }
    if let window = state.workspaces[key]?.strip.focusedWindow {
      focus.activate(window, in: key, from: .pointer)
    } else {
      state.focusedKey = key
    }
    presenter.render()
  }
}
