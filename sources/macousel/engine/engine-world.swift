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
  @ObservationIgnored private var isRefreshing = false
  @ObservationIgnored private var needsAnother = false
  @ObservationIgnored private var connecting: Task<Void, Never>?

  init(commands: any EngineCommanding, sleep: @escaping (Duration) async throws -> Void) {
    self.commands = commands
    self.sleep = sleep
  }

  var position: StripPosition? { snapshot?.stripPosition }

  func connect() {
    connecting?.cancel()
    connecting = Task {
      for _ in 0..<Self.connectAttempts {
        if let fetched = await commands.fetchSnapshot() {
          adopt(fetched)
          return
        }
        try? await sleep(Self.connectInterval)
        if Task.isCancelled { return }
      }
    }
  }

  func clear() {
    connecting?.cancel()
    connecting = nil
    snapshot = nil
  }

  func handle(_ event: EngineEvent) {
    if case .windowTitleChanged = event, snapshot == nil { return }
    refresh()
  }

  func refresh() {
    guard !isRefreshing else {
      needsAnother = true
      return
    }
    isRefreshing = true
    Task {
      repeat {
        needsAnother = false
        if let fetched = await commands.fetchSnapshot() { adopt(fetched) }
      } while needsAnother
      isRefreshing = false
    }
  }

  private func adopt(_ fetched: EngineSnapshot) {
    let previous = snapshot
    snapshot = fetched
    if previous?.focusedColumnIndex != fetched.focusedColumnIndex { onFocusMoved?(fetched) }
    onAdopted?(fetched)
  }
}
