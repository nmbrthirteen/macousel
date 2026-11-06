import Observation

@Observable
final class EngineWorld {
  static let connectAttempts = 20
  static let connectInterval = Duration.milliseconds(500)
  static let retryDelay = Duration.milliseconds(100)
  static let maximumRetries = 3

  private(set) var snapshot: EngineSnapshot?
  @ObservationIgnored var onFocusMoved: ((EngineSnapshot) -> Void)?
  @ObservationIgnored var onAdopted: ((EngineSnapshot) -> Void)?
  @ObservationIgnored private let commands: any EngineCommanding
  @ObservationIgnored private let sleep: (Duration) async throws -> Void
  @ObservationIgnored private var needsAnother = false
  @ObservationIgnored private var connecting: Task<Void, Never>?
  @ObservationIgnored private var refreshing: Task<Void, Never>?
  // A fetch that started before clear() must not adopt its result afterwards.
  @ObservationIgnored private var generation = 0
  @ObservationIgnored private var failures = 0
  @ObservationIgnored private var nextWaiter = 0
  @ObservationIgnored private var waiters: [Int: CheckedContinuation<Void, Never>] = [:]

  init(commands: any EngineCommanding, sleep: @escaping (Duration) async throws -> Void) {
    self.commands = commands
    self.sleep = sleep
  }

  var position: StripPosition? { snapshot?.stripPosition }

  func connect() {
    connecting?.cancel()
    let current = generation
    connecting = Task {
      for _ in 0..<Self.connectAttempts {
        if let fetched = await commands.fetchSnapshot() {
          if current == generation { adopt(fetched) }
          return
        }
        try? await sleep(Self.connectInterval)
        if Task.isCancelled { return }
      }
    }
  }

  func clear() {
    generation += 1
    connecting?.cancel()
    connecting = nil
    refreshing?.cancel()
    refreshing = nil
    needsAnother = false
    failures = 0
    snapshot = nil
  }

  func handle(_ event: EngineEvent) {
    let woken = waiters
    waiters = [:]
    woken.values.forEach { $0.resume() }
    // A title change carries everything it changes, so it skips the refetch.
    if case .windowTitleChanged(let id, let title) = event {
      guard var updated = snapshot else { return }
      updated.retitle(window: id, to: title)
      if updated != snapshot { adopt(updated) }
      return
    }
    refresh()
  }

  // Pollers waiting for the engine to settle wake as soon as it reports a change.
  func awaitEvent(upTo limit: Duration) async throws {
    nextWaiter += 1
    let id = nextWaiter
    await withCheckedContinuation { continuation in
      waiters[id] = continuation
      Task {
        try? await sleep(limit)
        waiters.removeValue(forKey: id)?.resume()
      }
    }
    try Task.checkCancellation()
  }

  func refresh() {
    guard refreshing == nil else {
      needsAnother = true
      return
    }
    let current = generation
    refreshing = Task {
      repeat {
        needsAnother = false
        let fetched = await commands.fetchSnapshot()
        guard current == generation else { break }
        if let fetched {
          failures = 0
          adopt(fetched)
        } else if failures < Self.maximumRetries {
          // The snapshot is stale until a fetch lands, so try once more shortly.
          failures += 1
          try? await sleep(Self.retryDelay)
          needsAnother = true
        }
      } while needsAnother && current == generation
      if current == generation { refreshing = nil }
    }
  }

  private func adopt(_ fetched: EngineSnapshot) {
    let previous = snapshot
    snapshot = fetched
    if previous?.focusedColumnIndex != fetched.focusedColumnIndex { onFocusMoved?(fetched) }
    onAdopted?(fetched)
  }
}

extension EngineSnapshot {
  fileprivate mutating func retitle(window id: Int32, to title: String) {
    for workspace in virtualWorkspaces.indices {
      for window in virtualWorkspaces[workspace].windows.indices
      where virtualWorkspaces[workspace].windows[window].windowId == id {
        virtualWorkspaces[workspace].windows[window].title = title
      }
    }
    if active.focusedWindowId == id { active.focusedWindowTitle = title }
  }
}
