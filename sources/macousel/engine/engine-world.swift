import Observation

@Observable
final class EngineWorld {
  static let connectAttempts = 20
  static let connectInterval = Duration.milliseconds(500)

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
    snapshot = nil
  }

  func handle(_ event: EngineEvent) {
    // A title change carries everything it changes, so it skips the refetch.
    if case .windowTitleChanged(let id, let title) = event {
      guard var updated = snapshot else { return }
      updated.retitle(window: id, to: title)
      if updated != snapshot { adopt(updated) }
      return
    }
    refresh()
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
        if let fetched = await commands.fetchSnapshot(), current == generation { adopt(fetched) }
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
