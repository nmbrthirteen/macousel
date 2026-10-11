import CoreGraphics
import StripCore
import WindowSystem

enum FocusSource {
  case command, pointer
}

final class FocusDriver {
  static let placementWait = Duration.milliseconds(30)
  private static let echoPeriod = Duration.milliseconds(250)

  private struct PendingActivation {
    var window: WindowID
    var requestedAt: ContinuousClock.Instant
  }

  var onUnconfirmedFocus: ((WindowID) -> Void)?
  var onActivated: ((WindowID) -> Void)?
  var needsRaise: (WindowID) -> Bool = { _ in true }
  let recents: RecentAppWindows

  private var lastCommandActivation: ContinuousClock.Instant?
  private var pendingActivation: PendingActivation?
  private var echoExpiry: Task<Void, Never>?
  private var focusRequestCount = 0

  private let state: TilingState
  private let windowSource: any WindowSource
  private let store: PreferencesStore
  private let pointer: any PointerDevice
  private let placer: any FramePlacer
  private let now: () -> ContinuousClock.Instant

  init(
    state: TilingState, source: any WindowSource, store: PreferencesStore,
    pointer: any PointerDevice, placer: any FramePlacer, now: @escaping () -> ContinuousClock.Instant
  ) {
    self.state = state
    self.windowSource = source
    self.store = store
    self.pointer = pointer
    self.placer = placer
    self.now = now
    recents = RecentAppWindows(source: source)
  }

  func observed(_ window: WindowID) {
    recents.note(window)
  }

  func activate(
    _ window: WindowID, in key: Workspace.Key, from source: FocusSource,
    layingOut layout: () -> Void = {}
  ) {
    state.focusedKey = key
    recents.note(window)
    let requestedAt = now()
    pendingActivation = PendingActivation(window: window, requestedAt: requestedAt)
    scheduleEchoExpiry(of: window)
    let raising = needsRaise(window)
    layout()
    requestFocus(of: window, raising: raising)
    onActivated?(window)
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

  private func requestFocus(of window: WindowID, raising: Bool) {
    guard let handle = windowSource.window(window.rawValue) else { return }
    focusRequestCount += 1
    let request = focusRequestCount
    placer.afterPlacement(of: handle, within: Self.placementWait) { [weak self] in
      guard let self, request == focusRequestCount else { return }
      windowSource.window(window.rawValue)?.focus(raising: raising)
    }
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
