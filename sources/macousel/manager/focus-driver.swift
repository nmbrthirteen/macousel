import CoreGraphics
import StripCore
import WindowSystem

enum FocusSource {
  case command, pointer
}

final class FocusDriver {
  private static let echoPeriod = Duration.milliseconds(250)

  private struct PendingActivation {
    var window: WindowID
    var requestedAt: ContinuousClock.Instant
  }

  var onUnconfirmedFocus: ((WindowID) -> Void)?

  private var lastCommandActivation: ContinuousClock.Instant?
  private var pendingActivation: PendingActivation?
  private var echoExpiry: Task<Void, Never>?

  private let state: TilingState
  private let windowSource: any WindowSource
  private let store: PreferencesStore
  private let pointer: any PointerDevice
  private let now: () -> ContinuousClock.Instant

  init(
    state: TilingState, source: any WindowSource, store: PreferencesStore,
    pointer: any PointerDevice, now: @escaping () -> ContinuousClock.Instant
  ) {
    self.state = state
    self.windowSource = source
    self.store = store
    self.pointer = pointer
    self.now = now
  }

  func activate(_ window: WindowID, in key: Workspace.Key, from source: FocusSource) {
    state.focusedKey = key
    let requestedAt = now()
    pendingActivation = PendingActivation(window: window, requestedAt: requestedAt)
    scheduleEchoExpiry(of: window)
    windowSource.window(window.rawValue)?.focus()
    guard source == .command else { return }
    lastCommandActivation = requestedAt
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
    if pending.requestedAt.duration(to: now()) < Self.echoPeriod { return true }
    pendingActivation = nil
    return false
  }

  func hasCommandActivation(within interval: Duration) -> Bool {
    lastCommandActivation.map { $0.duration(to: now()) < interval } ?? false
  }

  func stop() {
    echoExpiry?.cancel()
    echoExpiry = nil
  }

  private func scheduleEchoExpiry(of window: WindowID) {
    echoExpiry?.cancel()
    echoExpiry = Task { [weak self] in
      try? await Task.sleep(for: Self.echoPeriod)
      if !Task.isCancelled { self?.echoExpired(for: window) }
    }
  }

  private func echoExpired(for window: WindowID) {
    guard pendingActivation?.window == window else { return }
    pendingActivation = nil
    guard let focused = windowSource.focusedWindow() else { return }
    onUnconfirmedFocus?(WindowID(focused))
  }

  private func movePointer(onto window: WindowID, in key: Workspace.Key) {
    guard let frame = state.settledLayout(for: key)?[window]?.frame,
      !frame.contains(pointer.location)
    else { return }
    pointer.warp(to: frame.center)
  }
}
