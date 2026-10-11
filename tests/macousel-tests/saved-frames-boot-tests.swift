import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct SavedFramesBootTests {
  private func crashedSession(
    suite: IsolatedDefaults
  ) throws -> (originals: [CGWindowID: CGRect], tiled: [CGWindowID: CGRect]) {
    let first = try ControllerFixture(suite: suite, bootSession: "boot-1") {
      $0.layout.defaultWidth = 0.25
    }
    let row = first.openRow(3)
    let originals = first.frames(of: row)
    first.launch()
    return (originals, first.frames(of: row))
  }

  private func recoveringFixture(
    suite: IsolatedDefaults, bootSession: String, tiled: [CGWindowID: CGRect]
  ) throws -> [FakeWindow] {
    let fixture = try ControllerFixture(suite: suite, bootSession: bootSession)
    fixture.crashRecovery.isRecoveringFromCrash = true
    let row = tiled.keys.sorted().map { fixture.open($0) }
    for window in row { window.frame = tiled[window.id] }
    fixture.launch()
    return row
  }

  @Test func savedFramesFromTheSameBootAreRestored() throws {
    let suite = try IsolatedDefaults()
    let (originals, tiled) = try crashedSession(suite: suite)

    let row = try recoveringFixture(suite: suite, bootSession: "boot-1", tiled: tiled)

    #expect(
      Dictionary(uniqueKeysWithValues: row.compactMap { w in w.frame.map { (w.id, $0) } })
        == originals)
  }

  @Test func savedFramesFromAnotherBootAreDiscarded() throws {
    let suite = try IsolatedDefaults()
    let (_, tiled) = try crashedSession(suite: suite)

    let row = try recoveringFixture(suite: suite, bootSession: "boot-2", tiled: tiled)

    #expect(row.allSatisfy { $0.frame == tiled[$0.id] })
    #expect(row.allSatisfy { $0.framesSet.isEmpty })
  }

  @Test func theBootIdentifierIsStoredWithTheFrames() throws {
    let suite = try IsolatedDefaults()
    _ = try crashedSession(suite: suite)

    let data = try #require(suite.defaults.data(forKey: "originalFrames"))

    #expect(String(decoding: data, as: UTF8.self).contains("boot-1"))
  }

  @Test func theSystemBootSessionIsNotEmpty() {
    #expect(!BootSession.identifier.isEmpty)
  }
}
