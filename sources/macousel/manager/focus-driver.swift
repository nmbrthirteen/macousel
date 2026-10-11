import CoreGraphics
import StripCore
import WindowSystem

enum FocusSource {
  case command, pointer
}

final class FocusDriver {
  private var lastCommandActivation: ContinuousClock.Instant?

  private let state: TilingState
  private let windowSource: any WindowSource
  private let store: PreferencesStore
  private let pointer: any PointerDevice

  init(
    state: TilingState, source: any WindowSource, store: PreferencesStore,
    pointer: any PointerDevice
  ) {
    self.state = state
    self.windowSource = source
    self.store = store
    self.pointer = pointer
  }

  func activate(_ window: WindowID, in key: Workspace.Key, from source: FocusSource) {
    state.focusedKey = key
    windowSource.window(window.rawValue)?.focus()
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
      !frame.contains(pointer.location)
    else { return }
    pointer.warp(to: frame.center)
  }
}
