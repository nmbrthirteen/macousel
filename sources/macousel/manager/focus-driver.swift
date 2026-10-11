import CoreGraphics
import StripCore
import WindowSystem

enum FocusSource {
  case command, pointer
}

final class FocusDriver {
  private static let echoPeriod = Duration.milliseconds(500)

  private struct PendingActivation {
    var window: WindowID
    var requestedAt: ContinuousClock.Instant
  }

  private var lastCommandActivation: ContinuousClock.Instant?
  private var pendingActivation: PendingActivation?

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
    pendingActivation = PendingActivation(window: window, requestedAt: .now)
    windowSource.window(window.rawValue)?.focus()
    guard source == .command else { return }
    lastCommandActivation = .now
    if store.preferences.mouseFollowsFocus {
      movePointer(onto: window, in: key)
    }
  }

  func isEchoOfEarlierActivation(_ window: WindowID) -> Bool {
    guard let pending = pendingActivation else { return false }
    if pending.window == window {
      pendingActivation = nil
      return false
    }
    if ContinuousClock.now - pending.requestedAt < Self.echoPeriod { return true }
    pendingActivation = nil
    return false
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
