import CoreGraphics
import StripCore
import WindowSystem

enum FocusSource {
  case command, pointer
}

final class FocusDriver {
  private var lastCommandActivation: ContinuousClock.Instant?

  private let state: TilingState
  private let tracker: WindowTracker
  private let store: PreferencesStore

  init(state: TilingState, tracker: WindowTracker, store: PreferencesStore) {
    self.state = state
    self.tracker = tracker
    self.store = store
  }

  func activate(_ window: WindowID, in key: Workspace.Key, from source: FocusSource) {
    state.focusedKey = key
    tracker.windows[window.rawValue]?.focus()
    guard source == .command else { return }
    lastCommandActivation = .now
    if store.preferences.mouseFollowsFocus {
      movePointer(onto: window, in: key)
    }
  }

  func hasCommandActivation(within interval: Duration) -> Bool {
    lastCommandActivation.map { ContinuousClock.now - $0 < interval } ?? false
  }

  private func movePointer(onto window: WindowID, in key: Workspace.Key) {
    guard let frame = state.settledLayout(for: key)?[window]?.frame,
      !frame.contains(Pointer.location)
    else { return }
    Pointer.warp(to: frame.center)
  }
}
