import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct EngineDragTests {
  private let fixture = EngineDragFixture()
  private let gap = CGPoint(x: 1980, y: 100)
  private let far = CGSize(width: 300, height: 100)

  @Test func aPressOnAnUnknownWindowIsIgnored() async {
    await fixture.start()
    fixture.pointer.windowAtPoint = { _ in 99 }
    fixture.pointer.setServerBounds(CGRect(x: 0, y: 0, width: 100, height: 100), of: 99)

    fixture.pointer.pressPrimary(at: gap)
    fixture.pointer.setServerBounds(CGRect(x: 300, y: 100, width: 100, height: 100), of: 99)
    fixture.pointer.dragPrimary(to: gap)

    #expect(fixture.host.dropPreviewHistory.isEmpty)
  }

  @Test func aPressOnBareDesktopIsIgnored() async {
    await fixture.start()
    fixture.pointer.windowAtPoint = { _ in nil }

    fixture.pointer.pressPrimary(at: gap)
    fixture.pointer.dragPrimary(to: gap)

    #expect(fixture.host.dropPreviewHistory.isEmpty)
  }

  @Test func aPressBeforeAnySnapshotIsIgnored() {
    fixture.drag.start()

    fixture.press()
    fixture.drag(by: far, to: gap)

    #expect(fixture.host.dropPreviewHistory.isEmpty)
  }

  @Test func aMoveBeyondToleranceShowsThePreview() async {
    await fixture.start()

    fixture.press()
    fixture.drag(by: far, to: gap)

    #expect(fixture.host.dropPreview == CGRect(x: 1500, y: 0, width: 960, height: 400))
  }

  @Test func aMoveWithinToleranceShowsNothing() async {
    await fixture.start()

    fixture.press()
    fixture.drag(by: CGSize(width: 1, height: 1), to: gap)

    #expect(fixture.host.dropPreviewHistory.isEmpty)
  }

  @Test func thePollNoticesAMoveWithoutDraggedEvents() async {
    await fixture.start()

    fixture.press()
    fixture.pointer.setServerBounds(fixture.windowFrame(1).offsetBy(dx: 300, dy: 100), of: 1)
    fixture.pointer.movePrimarySilently(to: gap)
    fixture.clock.advance(by: DragPoller.interval)

    #expect(fixture.host.dropPreview != nil)
  }

  @Test func hoveringTheTopOfAWindowPreviewsAStack() async {
    await fixture.start()

    fixture.press()
    fixture.drag(by: far, to: CGPoint(x: 2480, y: 100))

    #expect(fixture.host.dropPreview == CGRect(x: 2000, y: 0, width: 960, height: 200))
  }

  @Test func hoveringTheBottomOfAWindowPreviewsTheLowerHalf() async {
    await fixture.start()

    fixture.press()
    fixture.drag(by: far, to: CGPoint(x: 2480, y: 300))

    #expect(fixture.host.dropPreview == CGRect(x: 2000, y: 200, width: 960, height: 200))
  }

  @Test func hoveringOverTheOwnSlotHidesThePreview() async {
    await fixture.start()

    fixture.press()
    fixture.drag(by: far, to: gap)
    fixture.drag(by: far, to: CGPoint(x: 480, y: 100))

    #expect(fixture.host.dropPreview == nil)
  }

  @Test func aSizeChangeIsAResizeAndNeverMovesAnything() async {
    await fixture.start()
    let frame = fixture.windowFrame(1)

    fixture.press()
    fixture.pointer.setServerBounds(
      CGRect(x: frame.minX, y: frame.minY, width: frame.width + 80, height: frame.height), of: 1)
    fixture.pointer.dragPrimary(to: gap)
    fixture.drag(by: far, to: gap)
    fixture.pointer.releasePrimary()

    #expect(fixture.host.dropPreviewHistory.isEmpty)
    #expect(!fixture.drag.isSettling)
    #expect(fixture.commands.sent.isEmpty)
  }

  @Test func escapeCancelsThePreviewAndTheDrop() async {
    await fixture.start()
    fixture.press()
    fixture.drag(by: far, to: gap)

    fixture.pointer.pressEscape()
    fixture.drag(by: far, to: gap)
    fixture.pointer.releasePrimary()

    #expect(fixture.host.dropPreview == nil)
    #expect(!fixture.pointer.isObservingEscape)
    #expect(!fixture.drag.isSettling)
    #expect(fixture.commands.sent.isEmpty)
  }

  @Test func releaseWaitsForTheStructureToSettleThenMovesTheWindow() async {
    await fixture.start()
    fixture.press()
    fixture.drag(by: far, to: gap)
    fixture.strip.columns = [[1], [3], [2]]
    let strip = fixture.strip
    fixture.probe.onSleep = { strip.columns = [[1], [2], [3]] }

    fixture.pointer.releasePrimary()

    #expect(await fixture.eventually { fixture.strip.columns == [[2], [1], [3]] })
    #expect(fixture.probe.sleeps == 1)
    #expect(fixture.commands.sent.contains(["window", "swap", "east"]))
    #expect(fixture.host.dropPreview == nil)
  }

  @Test func releaseRefreshesTheWorldAfterTheMove() async {
    await fixture.start()
    fixture.press()
    fixture.drag(by: far, to: gap)

    fixture.pointer.releasePrimary()

    #expect(
      await fixture.eventually {
        fixture.world.snapshot?.tiledColumns.windowIDs == [[WindowID(2)], [WindowID(1)], [WindowID(3)]]
      })
  }

  @Test func releaseOntoAWindowStacksIt() async {
    await fixture.start()
    fixture.press()
    fixture.drag(by: far, to: CGPoint(x: 2480, y: 100))

    fixture.pointer.releasePrimary()

    #expect(await fixture.eventually { fixture.strip.columns == [[2], [1, 3]] })
  }

  @Test func releaseSendsNothingWhenTheStructureNeverSettles() async {
    await fixture.start()
    fixture.press()
    fixture.drag(by: far, to: gap)
    fixture.strip.columns = [[1], [3], [2]]

    fixture.pointer.releasePrimary()

    #expect(await fixture.eventually { !fixture.drag.isSettling })
    #expect(fixture.probe.sleeps == EngineSettler.polls)
    #expect(fixture.commands.sent.isEmpty)
  }

  @Test func releaseOverTheOwnSlotSendsNothing() async {
    await fixture.start()
    fixture.press()
    fixture.drag(by: far, to: CGPoint(x: 480, y: 100))

    fixture.pointer.releasePrimary()

    #expect(!fixture.drag.isSettling)
    #expect(fixture.commands.sent.isEmpty)
  }

  @Test func anOpenOverviewIgnoresPresses() async {
    await fixture.start()
    fixture.overview.toggle(with: fixture.strip.snapshot)

    fixture.press()
    fixture.drag(by: far, to: gap)

    #expect(fixture.host.dropPreviewHistory.isEmpty)
  }

  @Test func aRunningReorderIgnoresPresses() async {
    await fixture.start()
    fixture.strip.ignoresCommands = true
    let reorder = fixture.reorder
    let task = Task { _ = await reorder.move(WindowID(2), to: .column(position: 0)) }
    #expect(await fixture.eventually { reorder.isRunning })

    fixture.press()
    fixture.drag(by: far, to: gap)
    task.cancel()

    #expect(fixture.host.dropPreviewHistory.isEmpty)
  }

  @Test func stoppingEndsObservationAndHidesThePreview() async {
    await fixture.start()
    fixture.press()
    fixture.drag(by: far, to: gap)
    #expect(fixture.host.dropPreview != nil)

    fixture.drag.stop()

    #expect(!fixture.pointer.isObservingPrimaryButton)
    #expect(!fixture.pointer.isObservingEscape)
    #expect(fixture.host.dropPreview == nil)
  }
}
