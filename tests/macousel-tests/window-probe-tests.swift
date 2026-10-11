import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct WindowProbeTests {
  private func harness(windows: CGWindowID) throws -> ReconcilerHarness {
    let harness = ReconcilerHarness(suite: try IsolatedDefaults())
    for id in 1...windows { harness.open(id, atX: CGFloat(id) * 100) }
    harness.reconciler.reconcile()
    return harness
  }

  @Test func aReconcileWithNoUnknownWindowsStartsNoProbe() throws {
    let harness = try harness(windows: 2)
    let probesAfterAdmission = harness.probe.probeCount
    var finished = 0

    harness.reconciler.reconcile(adoptingFocus: false, refreshingTabTitles: false) {
      finished += 1
    }

    #expect(harness.probe.probeCount == probesAfterAdmission)
    #expect(finished == 1)
  }

  @Test func aNewWindowIsProbedOnceAndThenTiled() async throws {
    let fixture = try ControllerFixture()
    _ = fixture.openRow(2)
    fixture.launch()

    let newcomer = fixture.open(3, app: .terminal, atX: 900)

    #expect(await fixture.becomes { !newcomer.framesSet.isEmpty })
    let probesForNewcomer = fixture.probe.requests.filter { $0.windows.contains(3) }
    #expect(probesForNewcomer.count == 1)
    #expect(newcomer.frame == ExpectedStrip(columns: [1, 3, 2]).frame(of: 3))
  }

  @Test func theStripStaysUnchangedWhileAProbeIsDeferredAndASecondRequestWaits() throws {
    let harness = try harness(windows: 1)
    let probesBefore = harness.probe.probeCount
    harness.probe.defersResults = true
    harness.open(2, atX: 300)
    var finished = 0

    harness.reconciler.reconcile { finished += 1 }
    harness.reconciler.reconcile { finished += 1 }

    #expect(harness.probe.probeCount == probesBefore + 1)
    #expect(harness.probe.heldCount == 1)
    #expect(harness.order() == [1])
    #expect(finished == 0)

    harness.probe.releaseHeldResults()

    #expect(harness.order() == [1, 2])
    #expect(harness.probe.probeCount == probesBefore + 2)
    #expect(finished == 1)

    harness.probe.releaseHeldResults()

    #expect(harness.probe.probeCount == probesBefore + 2)
    #expect(finished == 2)
  }

  @Test func requestsThatArriveDuringOneProbeShareASingleFollowUp() throws {
    let harness = try harness(windows: 1)
    let probesBefore = harness.probe.probeCount
    harness.probe.defersResults = true
    harness.open(2, atX: 300)

    for _ in 1...4 { harness.reconciler.reconcile() }
    harness.probe.releaseHeldResults()
    harness.probe.releaseHeldResults()

    #expect(harness.probe.probeCount == probesBefore + 2)
    #expect(harness.probe.heldCount == 0)
  }

  @Test func aWindowThatClosesWhileItsProbeIsInFlightIsIgnoredWhenTheResultArrives() throws {
    let harness = try harness(windows: 1)
    harness.probe.defersResults = true
    let closing = harness.open(2, atX: 300)
    harness.open(3, atX: 500)
    harness.reconciler.reconcile()

    harness.source.close(closing)
    harness.probe.releaseHeldResults()

    #expect(harness.order() == [1, 3])
    #expect(harness.source.window(2) == nil)
  }

  @Test func theFocusedWindowComesFromTheProbeResult() throws {
    let harness = try harness(windows: 2)
    let second = try #require(harness.source.fakeWindow(2))
    harness.source.takeFocusSilently(second)
    harness.probe.defersResults = true

    harness.reconciler.reconcile()

    #expect(harness.probe.requests.last?.includesFocus == true)
    #expect(harness.strip().focusedWindow != WindowID(2))

    harness.probe.releaseHeldResults()

    #expect(harness.strip().focusedWindow == WindowID(2))
  }

  @Test func theFocusIsNotRequestedWhenNoCallerWantsIt() throws {
    let harness = try harness(windows: 2)
    harness.open(3, atX: 700)

    harness.reconciler.reconcile(adoptingFocus: false, refreshingTabTitles: false)

    #expect(harness.probe.requests.last?.includesFocus == false)
    #expect(harness.probe.requests.last?.windows == [3])
  }

  @Test func aProbeTimeoutPausesThatAppForTwoSecondsAndKeepsItsWindowsInPlace() async throws {
    let fixture = try ControllerFixture()
    let slow = fixture.open(1, app: .editor, atX: 100, activating: true)
    let other = fixture.open(2, app: .browser, atX: 400)
    fixture.launch()
    slow.timesOutReads = true
    fixture.source.userResized(slow, to: try #require(slow.frame))
    let first = fixture.open(3, app: .terminal, atX: 900)
    #expect(await fixture.becomes { !first.framesSet.isEmpty })
    let readsAtTimeout = slow.fullScreenReadCount

    fixture.source.userResized(slow, to: try #require(slow.frame))
    fixture.clock.advance(by: .milliseconds(1900))
    let second = fixture.open(4, app: .terminal, atX: 900)
    #expect(await fixture.becomes { !second.framesSet.isEmpty })

    let expected = ExpectedStrip(columns: [1, 4, 3, 2])
    #expect(slow.fullScreenReadCount == readsAtTimeout)
    #expect(slow.frame == expected.frame(of: 1))
    #expect(other.frame == expected.frame(of: 2))

    slow.timesOutReads = false
    fixture.clock.advance(by: .milliseconds(100))
    let third = fixture.open(5, app: .terminal, atX: 900)
    #expect(await fixture.becomes { !third.framesSet.isEmpty })
    #expect(slow.fullScreenReadCount > readsAtTimeout)
  }

  @Test func theAdmissionFrameComesFromTheProbeWithoutAnotherRead() throws {
    let fixture = try ControllerFixture()
    let original = CGRect(x: 300, y: 100, width: 400, height: 300)
    let window = fixture.open(1, atX: 300, activating: true)

    fixture.launch()
    let readsAfterAdmission = window.frameReadCount
    fixture.manager.perform(.togglePaused)

    #expect(readsAfterAdmission == 1)
    #expect(window.frameReadCount == 1)
    #expect(window.framesSet.last == original)
  }
}
