import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct EngineSupervisorTests {
  private let harness = EngineHarness()

  private func supervisor() throws -> EngineSupervisor {
    let store = PreferencesStore(defaults: try IsolatedDefaults().defaults)
    return harness.makeSupervisor(sync: harness.makeSync(store: store))
  }

  @Test func doesNotSpawnWhileAccessibilityIsMissing() async throws {
    harness.isTrusted = false
    let engine = try supervisor()

    engine.start()

    #expect(await harness.eventually { engine.state == .needsPermission })
    #expect(harness.launcher.launches.isEmpty)
  }

  @Test func clearsAnOrphanBeforeSpawning() async throws {
    harness.commands.isAlive = true
    let engine = try supervisor()

    engine.start()

    #expect(await harness.eventually { engine.state == .running })
    let quit = try #require(harness.log.index(of: "send quit"))
    let launch = try #require(harness.log.index(of: "launch"))
    #expect(quit < launch)
  }

  @Test func writesTheConfigurationBeforeSpawning() async throws {
    let engine = try supervisor()

    engine.start()

    #expect(await harness.eventually { engine.state == .running })
    let written = try #require(harness.log.index(of: "write config"))
    let launch = try #require(harness.log.index(of: "launch"))
    #expect(written < launch)
    #expect(harness.files.handle.operations.contains("close"))
  }

  @Test func refusesToStartNextToAStandaloneInstance() async throws {
    harness.standalone.isAlive = true
    let engine = try supervisor()

    engine.start()

    #expect(await harness.eventually { engine.state.failure == .standaloneRunning })
    #expect(harness.launcher.launches.isEmpty)
    #expect(
      EngineFailure.standaloneRunning.message
        == "Paneru is already running on this Mac. Quit it, since two window managers would both move your windows."
    )
  }

  @Test func reportsAMissingHelper() async throws {
    harness.hasHelper = false
    let engine = try supervisor()

    engine.start()

    #expect(await harness.eventually { engine.state.failure == .notBundled })
    #expect(EngineFailure.notBundled.message == "The engine is not bundled in this build.")
  }

  @Test func restartsAfterACrashWithGrowingBackoff() async throws {
    let engine = try supervisor()
    engine.start()
    #expect(await harness.eventually { harness.launcher.processes.count == 1 })

    harness.launcher.processes[0].crash()
    #expect(await harness.eventually { harness.launcher.processes.count == 2 })
    harness.launcher.processes[1].crash()
    #expect(await harness.eventually { harness.launcher.processes.count == 3 })
    harness.launcher.processes[2].crash()
    #expect(await harness.eventually { harness.launcher.processes.count == 4 })

    #expect(harness.sleeps == [.seconds(1), .seconds(2), .seconds(4)])
    #expect(engine.restartCount == 3)
  }

  @Test func givesUpAfterThreeRestartsInAMinute() async throws {
    let engine = try supervisor()
    engine.start()
    for attempt in 1...3 {
      #expect(await harness.eventually { harness.launcher.processes.count == attempt })
      harness.launcher.processes[attempt - 1].crash()
    }
    #expect(await harness.eventually { harness.launcher.processes.count == 4 })

    harness.launcher.processes[3].crash()

    #expect(await harness.eventually { engine.state.failure == .restartedTooOften })
    #expect(harness.launcher.processes.count == 4)
  }

  @Test func forgetsRestartsOlderThanAMinute() async throws {
    let engine = try supervisor()
    engine.start()
    for attempt in 1...5 {
      #expect(await harness.eventually { harness.launcher.processes.count == attempt })
      harness.now += .seconds(61)
      harness.launcher.processes[attempt - 1].crash()
    }

    #expect(await harness.eventually { harness.launcher.processes.count == 6 })
    #expect(engine.state == .running)
  }

  @Test func stopsWithSigtermAndWaitsForTheExit() async throws {
    let engine = try supervisor()
    engine.start()
    #expect(await harness.eventually { engine.state == .running })

    engine.stop()

    #expect(harness.log.entries.filter { $0 == "terminate" }.count == 1)
    #expect(!harness.log.entries.contains("kill"))
    #expect(engine.state == .stopped)
  }

  @Test func escalatesToSigkillAfterTwoSeconds() async throws {
    harness.launcher.exitsOnTerminate = false
    let engine = try supervisor()
    engine.start()
    #expect(await harness.eventually { engine.state == .running })

    engine.stop()

    let terminate = try #require(harness.log.index(of: "terminate"))
    let kill = try #require(harness.log.index(of: "kill"))
    #expect(terminate < kill)
    let waited = harness.pauses.reduce(Duration.zero, +)
    #expect(waited == .seconds(2))
  }

  @Test func anExitAfterStopIsNotRestarted() async throws {
    let engine = try supervisor()
    engine.start()
    #expect(await harness.eventually { engine.state == .running })

    engine.stop()
    harness.launcher.processes[0].crash()
    await Task.yield()

    #expect(harness.launcher.processes.count == 1)
    #expect(engine.state == .stopped)
  }

  @Test func reportsAConfigurationThatCannotBeWritten() async throws {
    harness.files.handle.failsOnWrite = true
    let engine = try supervisor()

    engine.start()

    #expect(await harness.eventually { engine.state.failure == .configUnwritable })
    #expect(harness.launcher.launches.isEmpty)
  }

  @Test func startsAgainAfterAFailure() async throws {
    harness.standalone.isAlive = true
    let engine = try supervisor()
    engine.start()
    #expect(await harness.eventually { engine.state.failure != nil })

    harness.standalone.isAlive = false
    engine.start()

    #expect(await harness.eventually { engine.state == .running })
  }
}
