import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ScratchpadReleaseTests {
  private func launchedRow() throws -> (ControllerFixture, [FakeWindow], [CGWindowID: CGRect]) {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    let originals = fixture.frames(of: row)
    fixture.launch()
    return (fixture, row, originals)
  }

  @Test func quittingRestoresTheHiddenScratchpadWindow() throws {
    let (fixture, row, originals) = try launchedRow()
    fixture.manager.perform(.sendToScratchpad)

    fixture.quit()

    #expect(fixture.frames(of: row) == originals)
  }

  @Test func quittingRestoresTheShownScratchpadWindow() throws {
    let (fixture, row, originals) = try launchedRow()
    fixture.manager.perform(.sendToScratchpad)
    fixture.manager.perform(.toggleScratchpad)

    fixture.quit()

    #expect(row[0].frame == originals[1])
    #expect(fixture.frames(of: row) == originals)
  }

  @Test func pausingRestoresTheScratchpadWindowAndResumingTilesItAgain() throws {
    let (fixture, row, originals) = try launchedRow()
    fixture.manager.perform(.sendToScratchpad)
    let withoutScratchpad = fixture.frames(of: [row[1], row[2]])

    fixture.manager.perform(.togglePaused)
    #expect(fixture.frames(of: row) == originals)

    fixture.manager.perform(.togglePaused)
    #expect(fixture.manager.status == .running)
    #expect(row[0].frame != originals[1])
    #expect(fixture.frames(of: [row[1], row[2]]) != withoutScratchpad)
  }

  @Test func losingAccessibilityKeepsTheScratchpadWindowRestorable() async throws {
    let suite = try IsolatedDefaults()
    let fixture = try ControllerFixture(suite: suite)
    let row = fixture.openRow(3)
    let originals = fixture.frames(of: row)
    fixture.launch()
    fixture.manager.perform(.sendToScratchpad)

    fixture.environment.isAccessibilityGranted = false
    #expect(await fixture.becomes { fixture.manager.status == .needsPermission })
    fixture.quit()

    let restorer = WindowRestorer(defaults: suite.defaults, bootSession: "boot-1")
    restorer.restoreSaved(row, on: [fixture.display])
    #expect(fixture.frames(of: row) == originals)
  }
}
