@testable import Macousel

@MainActor
final class FakeEngineProcess: EngineProcess {
  let exits: AsyncStream<Int32>
  var exitsOnTerminate = true
  private(set) var isRunning = true
  private let continuation: AsyncStream<Int32>.Continuation
  private let log: EngineCallLog

  init(log: EngineCallLog) {
    self.log = log
    (exits, continuation) = AsyncStream<Int32>.makeStream()
  }

  func terminate() {
    log.append("terminate")
    if exitsOnTerminate { finish(with: 0) }
  }

  func kill() {
    log.append("kill")
    finish(with: 9)
  }

  func crash(status: Int32 = 1) {
    finish(with: status)
  }

  private func finish(with status: Int32) {
    guard isRunning else { return }
    isRunning = false
    continuation.yield(status)
    continuation.finish()
  }
}

@MainActor
final class FakeEngineLauncher: EngineProcessLauncher {
  struct Failure: Error {}

  var fails = false
  var exitsOnTerminate = true
  private(set) var launches: [EngineLaunch] = []
  private(set) var processes: [FakeEngineProcess] = []
  private let log: EngineCallLog

  init(log: EngineCallLog) {
    self.log = log
  }

  func launch(_ launch: EngineLaunch) throws -> any EngineProcess {
    if fails { throw Failure() }
    log.append("launch")
    launches.append(launch)
    let process = FakeEngineProcess(log: log)
    process.exitsOnTerminate = exitsOnTerminate
    processes.append(process)
    return process
  }
}
