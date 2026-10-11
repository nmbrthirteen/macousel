import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ReconcileReadsTests {
  private func triggerReconcile(_ fixture: ControllerFixture, marker: CGWindowID) async -> Bool {
    let window = fixture.open(marker, app: .terminal, atX: 900)
    return await fixture.becomes { window.frame != nil && window.framesSet.count > 0 }
  }

  @Test func fullScreenIsReadOncePerWindowAcrossReconciles() async throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(2)
    fixture.launch()
    let readsAfterLaunch = row[0].fullScreenReadCount

    #expect(await triggerReconcile(fixture, marker: 3))
    #expect(await triggerReconcile(fixture, marker: 4))

    #expect(readsAfterLaunch == 1)
    #expect(row[0].fullScreenReadCount == readsAfterLaunch)
  }

  @Test func aResizeEventMakesTheNextReconcileReadFullScreenAgain() async throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(2)
    fixture.launch()
    let readsAfterLaunch = row[0].fullScreenReadCount

    fixture.source.userResized(row[0], to: try #require(row[0].frame))
    #expect(await triggerReconcile(fixture, marker: 3))

    #expect(row[0].fullScreenReadCount == readsAfterLaunch + 1)
  }

  @Test func aTimedOutReadPausesReadsForThatAppAndKeepsItsWindowsInPlace() async throws {
    let fixture = try ControllerFixture()
    let slow = fixture.open(1, app: .editor, atX: 100, activating: true)
    let other = fixture.open(2, app: .browser, atX: 400)
    fixture.launch()
    slow.timesOutReads = true
    fixture.source.userResized(slow, to: try #require(slow.frame))
    #expect(await triggerReconcile(fixture, marker: 3))
    let readsAfterTimeout = slow.fullScreenReadCount

    fixture.source.userResized(slow, to: try #require(slow.frame))
    #expect(await triggerReconcile(fixture, marker: 4))

    #expect(slow.fullScreenReadCount == readsAfterTimeout)
    let expected = ExpectedStrip(columns: [1, 4, 3, 2])
    #expect(slow.frame == expected.frame(of: 1))
    #expect(other.frame == expected.frame(of: 2))
  }

  @Test func readsResumeAfterTheUnresponsivePause() async throws {
    let fixture = try ControllerFixture()
    let slow = fixture.open(1, app: .editor, atX: 100, activating: true)
    fixture.launch()
    slow.timesOutReads = true
    fixture.source.userResized(slow, to: try #require(slow.frame))
    #expect(await triggerReconcile(fixture, marker: 3))
    let readsAfterTimeout = slow.fullScreenReadCount
    slow.timesOutReads = false

    fixture.clock.advance(by: .seconds(3))
    #expect(await triggerReconcile(fixture, marker: 4))

    #expect(slow.fullScreenReadCount > readsAfterTimeout)
  }

  @Test func eachNewWindowFrameIsReadOnlyForAdmissionAndRestore() throws {
    let fixture = try ControllerFixture { $0.animationSpeed = .fast }
    let window = fixture.open(1, atX: 300, activating: true)

    fixture.launch()

    #expect(window.frameReadCount == 2)
  }
}
