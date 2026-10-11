import CoreGraphics
import StripCore
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ScratchpadTests {
  private let pair = [Display.leftOfPair, Display.rightOfPair]

  private func launchedRow(count: CGWindowID = 3) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(count)
    fixture.launch()
    return (fixture, row)
  }

  private func centered(in display: Display) -> CGRect {
    let area = display.visibleFrame
    let size = CGSize(
      width: area.width * Scratchpad.widthFraction, height: area.height * Scratchpad.heightFraction)
    return CGRect(
      x: area.midX - size.width / 2, y: area.midY - size.height / 2, width: size.width,
      height: size.height)
  }

  @Test func sendingRemovesTheWindowFromTheStripAndParksItBeyondTheRightEdge() throws {
    let (fixture, row) = try launchedRow()
    let tiledSize = try #require(row[0].frame?.size)

    fixture.manager.perform(.sendToScratchpad)

    let parked = try #require(row[0].frame)
    let expected = ExpectedStrip(columns: [2, 3])
    #expect(parked.minX == fixture.display.frame.maxX - ParkingPolicy.visibleSliver)
    #expect(parked.size == tiledSize)
    #expect(fixture.frames(of: [row[1], row[2]]) == expected.frames.filter { $0.key != 1 })
    #expect(row[1].focusCount == 1)
  }

  @Test func theStripNoLongerReclaimsTheScratchpadWindow() async throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.sendToScratchpad)
    let parked = try #require(row[0].frame)
    let placements = row[0].framesSet.count

    let newcomer = fixture.open(4, atX: 800)

    #expect(await fixture.becomes { !newcomer.framesSet.isEmpty })
    #expect(row[0].frame == parked)
    #expect(row[0].framesSet.count == placements)
  }

  @Test func togglingShowsItCenteredAtTheNamedSizeAndFocusesIt() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.sendToScratchpad)

    fixture.manager.perform(.toggleScratchpad)

    #expect(row[0].frame == centered(in: fixture.display))
    #expect(row[0].focusCount == 1)
    #expect(fixture.source.focusedWindow()?.id == 1)
    #expect(fixture.placer.submissions.last == .init(window: 1, frame: centered(in: fixture.display)))
  }

  @Test func togglingAgainHidesItAndFocusReturnsToTheStrip() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.sendToScratchpad)
    fixture.manager.perform(.toggleScratchpad)
    let focusBeforeHiding = row[1].focusCount

    fixture.manager.perform(.toggleScratchpad)

    let hidden = try #require(row[0].frame)
    #expect(hidden.minX == fixture.display.frame.maxX - ParkingPolicy.visibleSliver)
    #expect(hidden.size == centered(in: fixture.display).size)
    #expect(row[1].focusCount == focusBeforeHiding + 1)
    #expect(fixture.source.focusedWindow()?.id == 2)
  }

  @Test func shownScratchpadWithAnotherWindowFocusedGetsFocusInsteadOfHiding() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.sendToScratchpad)
    fixture.manager.perform(.toggleScratchpad)
    fixture.source.takeFocusSilently(row[1])

    fixture.manager.perform(.toggleScratchpad)

    #expect(row[0].frame == centered(in: fixture.display))
    #expect(row[0].focusCount == 2)
    #expect(fixture.source.focusedWindow()?.id == 1)
  }

  @Test func showingUsesTheDisplayThatIsActiveAtThatMoment() throws {
    let fixture = try ControllerFixture(displays: pair)
    let sent = fixture.open(1, atX: 100, activating: true)
    let second = fixture.open(2, atX: 400)
    let right = fixture.open(3, atX: 1100)
    fixture.launch()
    fixture.manager.perform(.sendToScratchpad)
    fixture.clock.advance(by: .milliseconds(300))
    fixture.source.focus(right)

    fixture.manager.perform(.toggleScratchpad)

    #expect(sent.frame == centered(in: .rightOfPair))

    fixture.manager.perform(.toggleScratchpad)
    fixture.clock.advance(by: .milliseconds(300))
    fixture.source.focus(second)
    fixture.manager.perform(.toggleScratchpad)

    #expect(sent.frame == centered(in: .leftOfPair))
  }

  @Test func sendingASecondWindowReturnsTheFirstToTheStrip() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.sendToScratchpad)

    fixture.manager.perform(.sendToScratchpad)

    let expected = ExpectedStrip(columns: [3, 1])
    let parked = try #require(row[1].frame)
    #expect(parked.minX == fixture.display.frame.maxX - ParkingPolicy.visibleSliver)
    #expect(row[0].frame == expected.frame(of: 1))
    #expect(row[2].frame == expected.frame(of: 3))

    fixture.manager.perform(.toggleScratchpad)
    #expect(row[1].frame == centered(in: fixture.display))
    #expect(row[0].frame == expected.frame(of: 1))
  }

  @Test func closingTheScratchpadWindowEmptiesIt() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.sendToScratchpad)
    fixture.source.close(row[0])
    let submissions = fixture.placer.submissions.count

    fixture.manager.perform(.toggleScratchpad)

    #expect(fixture.placer.submissions.count == submissions)
  }

  @Test func closingTheScratchpadWindowLetsTheNextSendStartFresh() throws {
    let (fixture, row) = try launchedRow()
    fixture.manager.perform(.sendToScratchpad)
    fixture.source.close(row[0])

    fixture.manager.perform(.sendToScratchpad)
    fixture.manager.perform(.toggleScratchpad)

    #expect(row[1].frame == centered(in: fixture.display))
    #expect(row[2].frame != centered(in: fixture.display))
  }

  @Test func emptyScratchpadTogglesNothing() throws {
    let (fixture, row) = try launchedRow()
    let before = fixture.placer.submissions.count
    let focusCounts = row.map(\.focusCount)

    fixture.manager.perform(.toggleScratchpad)

    #expect(fixture.placer.submissions.count == before)
    #expect(row.map(\.focusCount) == focusCounts)
  }

  @Test func sendingWithoutAFocusedTiledWindowDoesNothing() throws {
    let fixture = try ControllerFixture()
    fixture.launch()

    fixture.manager.perform(.sendToScratchpad)
    fixture.manager.perform(.toggleScratchpad)

    #expect(fixture.placer.submissions.isEmpty)
  }
}
