import Foundation
import Observation
import WindowSystem
import os

@Observable
final class EngineSupervisor {
  static let orphanChecks = 20
  static let orphanInterval = Duration.milliseconds(100)
  // Paneru saves its state and puts every window back on SIGTERM, which takes a moment.
  static let terminationPolls = 100
  static let terminationInterval = Duration.milliseconds(50)

  private static let logger = Logger(subsystem: Log.subsystem, category: "engine")

  struct Dependencies {
    var launcher: any EngineProcessLauncher
    var commands: any EngineCommanding
    var standalone: any EngineCommanding
    var plan: () -> EngineLaunch?
    var isTrusted: () -> Bool
    var writeConfig: () throws -> Void
    var now: () -> ContinuousClock.Instant
    var sleep: (Duration) async throws -> Void
    var isScreenLocked: () -> Bool = { false }
  }

  static let lockedScreenRecheck = Duration.seconds(1)

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
  @ObservationIgnored private var retiring: [ObjectIdentifier: any EngineProcess] = [:]

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
    if let process { retire(process) }
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
    await awaitRetired()
    let cleared = await clearOrphan()
    guard current == generation else { return }
    guard cleared else {
      state = .failed(.orphanRunning)
      return
    }
    // A locked screen hides every window and Space from the engine. Starting now would adopt
    // none of them, and the ones nobody touches after unlock would stay unmanaged.
    while dependencies.isScreenLocked() {
      try? await dependencies.sleep(Self.lockedScreenRecheck)
      guard current == generation else { return }
    }
    launch(generation: current)
  }

  private func clearOrphan() async -> Bool {
    guard await dependencies.commands.isAnswering() else { return true }
    await dependencies.commands.send(["quit"])
    for _ in 0..<Self.orphanChecks {
      if !(await dependencies.commands.isAnswering()) { return true }
      try? await dependencies.sleep(Self.orphanInterval)
    }
    Self.logger.error("An engine from an earlier run still answers after quit")
    return false
  }

  private func launch(generation current: Int) {
    guard let launch = dependencies.plan() else {
      state = .failed(.notBundled)
      return
    }
    do {
      try dependencies.writeConfig()
    } catch {
      Self.logger.error("Could not write the engine configuration: \(error, privacy: .public)")
      state = .failed(.configUnwritable)
      return
    }
    do {
      let started = try dependencies.launcher.launch(launch)
      process = started
      state = .running
      tasks.append(Task { await watch(started, generation: current) })
    } catch {
      Self.logger.error("Could not launch the engine: \(error, privacy: .public)")
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
      await boot(generation: current)
    }
  }

  // Waits off the caller so quitting or switching engines never blocks the main thread. If
  // Macousel exits before the grace runs out, the engine watchdog finishes the job.
  private func retire(_ running: any EngineProcess) {
    running.terminate()
    let key = ObjectIdentifier(running)
    retiring[key] = running
    Task {
      for _ in 0..<Self.terminationPolls {
        if !running.isRunning { break }
        try? await dependencies.sleep(Self.terminationInterval)
      }
      if running.isRunning { running.kill() }
      retiring[key] = nil
    }
  }

  private func awaitRetired() async {
    while retiring.values.contains(where: \.isRunning) {
      try? await dependencies.sleep(Self.terminationInterval)
    }
  }
}
