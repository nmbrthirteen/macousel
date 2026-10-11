import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct EngineSwitchTests {
  private let harness = EngineHarness()

  private func makeFixture(engine: WindowEngine) throws -> ControllerFixture {
    try ControllerFixture(
      preferences: { $0.engine = engine },
      paneru: { [harness] store, environment, shortcuts in
        harness.makeEngine(store: store, environment: environment, shortcuts: shortcuts)
      })
  }

  @Test func startsTheEngineThePreferenceSelects() async throws {
    let fixture = try makeFixture(engine: .paneru)

    fixture.launch()

    #expect(await harness.eventually { harness.launcher.processes.count == 1 })
    #expect(fixture.manager.selected == .paneru)
    #expect(fixture.manager.status == .running)
  }

  @Test func theBuiltInEngineNeverTouchesTheHelper() throws {
    let fixture = try makeFixture(engine: .builtIn)
    _ = fixture.openRow(2)

    fixture.launch()

    #expect(fixture.manager.status == .running)
    #expect(harness.launcher.launches.isEmpty)
  }

  @Test func switchingToPaneruStopsTheBuiltInEngineAndStartsTheHelper() async throws {
    let fixture = try makeFixture(engine: .builtIn)
    let row = fixture.openRow(3)
    let originals = fixture.frames(of: row)
    fixture.launch()
    #expect(fixture.frames(of: row) != originals)

    fixture.store.preferences.engine = .paneru

    #expect(fixture.frames(of: row) == originals)
    #expect(await harness.eventually { harness.launcher.processes.count == 1 })
    #expect(fixture.manager.selected == .paneru)
    let paused = Set(Action.defaultShortcuts[.togglePaused] ?? [])
    let overview = Set(Action.defaultShortcuts[.toggleOverview] ?? [])
    #expect(fixture.shortcuts.boundHotkeys == paused.union(overview))
  }

  @Test func switchingBackStopsTheHelperAndTilesAgain() async throws {
    let fixture = try makeFixture(engine: .paneru)
    let row = fixture.openRow(3)
    let originals = fixture.frames(of: row)
    fixture.launch()
    #expect(await harness.eventually { harness.launcher.processes.count == 1 })

    fixture.store.preferences.engine = .builtIn

    #expect(harness.log.entries.contains("terminate"))
    #expect(fixture.manager.selected == .builtIn)
    #expect(fixture.manager.status == .running)
    #expect(await fixture.becomes { fixture.frames(of: row) != originals })
    #expect(fixture.shortcuts.boundHotkeys == Set(Action.defaultShortcuts.values.flatMap { $0 }))
  }

  @Test func otherPreferenceChangesLeaveTheRunningEngineAlone() async throws {
    let fixture = try makeFixture(engine: .paneru)
    fixture.launch()
    #expect(await harness.eventually { harness.launcher.processes.count == 1 })

    fixture.store.preferences.layout.innerGap = 12

    #expect(harness.launcher.processes.count == 1)
    #expect(!harness.log.entries.contains("terminate"))
    let written = String(decoding: harness.files.handle.contents, as: UTF8.self)
    #expect(written.contains("horizontal_padding = 6"))
  }

  @Test func quittingStopsTheHelper() async throws {
    let fixture = try makeFixture(engine: .paneru)
    fixture.launch()
    #expect(await harness.eventually { harness.launcher.processes.count == 1 })

    fixture.manager.shutdown()

    #expect(harness.log.entries.contains("terminate"))
  }

  @Test func forwardsActionsToTheActiveEngineOnly() async throws {
    let fixture = try makeFixture(engine: .paneru)
    fixture.launch()
    #expect(await harness.eventually { harness.launcher.processes.count == 1 })

    fixture.manager.perform(.focusRight)

    #expect(await harness.eventually { harness.commands.sent == [["window", "focus", "east"]] })
  }

  @Test func theDiagnosticsReportNamesTheSelectedEngine() throws {
    let fixture = try makeFixture(engine: .builtIn)

    let report = fixture.manager.engineReport()

    #expect(report.selected == .builtIn)
    #expect(report.text.contains("Engine: Built-in"))
    #expect(report.text.contains("Engine version: 0.5.2"))
    #expect(report.text.contains("Engine helper found: yes"))
    #expect(report.text.contains("[bindings]"))
  }
}
