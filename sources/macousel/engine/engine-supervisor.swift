import Foundation
import Observation

@Observable
final class EngineSupervisor {
  static let orphanChecks = 20
  static let orphanInterval = Duration.milliseconds(100)
  static let terminationPolls = 40
  static let terminationInterval = Duration.milliseconds(50)

  struct Dependencies {
    var launcher: any EngineProcessLauncher
    var commands: any EngineCommanding
    var standalone: any EngineCommanding
    var plan: () -> EngineLaunch?
    var isTrusted: () -> Bool
    var writeConfig: () throws -> Void
    var now: () -> ContinuousClock.Instant
    var sleep: (Duration) async throws -> Void
    var pause: (Duration) -> Void
  }

  private(set) var state = EngineRunState.stopped {
    didSet { if state != oldValue { onStateChange?(state) } }
  }
  private(set) var restartCount = 0
  @ObservationIgnored var onStateChange: ((EngineRunState) -> Void)?
  @ObservationIgnored private let dependencies: Dependencies
  @ObservationIgnored private var process: (any EngineProcess)?
  @ObservationIgnored private var policy = EngineRestartPolicy()
  @ObservationIgnored private var generation = 0
  @ObservationIgnored private var tasks: [Task<Void, Never>] = []

  init(_ dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  func start() {
    guard state == .stopped || state == .needsPermission || state.failure != nil else { return }
    generation += 1
    policy.reset()
    restartCount = 0
    state = .starting
    let current = generation
    tasks.append(Task { await boot(generation: current) })
  }

  func stop() {
    generation += 1
    tasks.forEach { $0.cancel() }
    tasks = []
    if let process { terminateAndWait(process) }
    process = nil
    state = .stopped
  }

  private func boot(generation current: Int) async {
    guard dependencies.isTrusted() else {
      state = .needsPermission
      return
    }
    guard dependencies.plan() != nil else {
      state = .failed(.notBundled)
      return
    }
    guard !(await dependencies.standalone.isAnswering()) else {
      if current == generation { state = .failed(.standaloneRunning) }
      return
    }
    await clearOrphan()
    guard current == generation else { return }
    launch(generation: current)
  }

  private func clearOrphan() async {
    guard await dependencies.commands.isAnswering() else { return }
    await dependencies.commands.send(["quit"])
    for _ in 0..<Self.orphanChecks {
      if !(await dependencies.commands.isAnswering()) { return }
      try? await dependencies.sleep(Self.orphanInterval)
    }
  }

  private func launch(generation current: Int) {
    guard let launch = dependencies.plan() else {
      state = .failed(.notBundled)
      return
    }
    do {
      try dependencies.writeConfig()
    } catch {
      state = .failed(.configUnwritable)
      return
    }
    do {
      let started = try dependencies.launcher.launch(launch)
      process = started
      state = .running
      tasks.append(Task { await watch(started, generation: current) })
    } catch {
      state = .failed(.launchFailed)
    }
  }

  private func watch(_ watched: any EngineProcess, generation current: Int) async {
    for await _ in watched.exits {}
    guard current == generation, state == .running else { return }
    process = nil
    switch policy.decide(at: dependencies.now()) {
    case .giveUp:
      state = .failed(.restartedTooOften)
    case .restart(let delay):
      restartCount += 1
      state = .waitingToRestart
      try? await dependencies.sleep(delay)
      guard current == generation, state == .waitingToRestart else { return }
      launch(generation: current)
    }
  }

  private func terminateAndWait(_ running: any EngineProcess) {
    running.terminate()
    for _ in 0..<Self.terminationPolls {
      if !running.isRunning { return }
      dependencies.pause(Self.terminationInterval)
    }
    running.kill()
  }
}
