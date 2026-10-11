import CoreGraphics
import StripCore
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct OverviewTests {
  private func selection(of fixture: ControllerFixture) -> WindowID? {
    fixture.overlays.overview?.snapshot.selection
  }

  @Test func openingShowsEveryColumnOnTheActiveDisplayWithTheFocusedWindowSelected() throws {
    let fixture = try ControllerFixture()
    _ = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)

    fixture.manager.perform(.toggleOverview)

    let overview = try #require(fixture.overlays.overview)
    #expect(overview.displayFrame == fixture.display.frame)
    #expect(overview.snapshot.selection == WindowID(2))
    #expect(overview.snapshot.columns.map { $0.cards.map(\.window) } == [[WindowID(1)], [WindowID(2)], [WindowID(3)]])
    #expect(overview.snapshot.stripHeight == fixture.display.visibleFrame.height - 2 * fixture.config.outerGap)
  }

  @Test func cardsCarryTheTitleCapturedAtAdmissionAndTheBundleIdentifier() throws {
    let fixture = try ControllerFixture()
    let notes = fixture.open(1, app: .editor, title: "Notes", atX: 100, activating: true)
    fixture.open(2, app: .browser, title: "Docs", atX: 400)
    fixture.launch()
    notes.title = "Renamed later"

    fixture.manager.perform(.toggleOverview)

    let cards = try #require(fixture.overlays.overview).snapshot.columns.flatMap(\.cards)
    #expect(cards.map(\.title) == ["Notes", "Docs"])
    #expect(cards.map(\.bundleIdentifier) == ["test.editor", "test.browser"])
  }

  @Test func emptyTitleFallsBackToTheAppName() throws {
    let fixture = try ControllerFixture()
    fixture.open(1, app: .terminal, title: "", atX: 100, activating: true)
    fixture.launch()

    fixture.manager.perform(.toggleOverview)

    let card = try #require(fixture.overlays.overview?.snapshot.columns.first?.cards.first)
    #expect(card.title == "Terminal")
  }

  @Test func columnWidthsMatchTheLayoutAndStacksCarryTheirHeightShares() throws {
    let fixture = try ControllerFixture()
    _ = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.taller)

    fixture.manager.perform(.toggleOverview)

    let columns = try #require(fixture.overlays.overview).snapshot.columns
    let expected = ExpectedStrip(columns: [1, 2, 3])
    let layoutWidth = try #require(expected.layout.placements.first?.frame.width)
    #expect(columns.count == 2)
    #expect(columns[0].width == Double(layoutWidth))
    #expect(columns[0].cards.count == 2)
    #expect(columns[0].cards.map(\.heightShare).reduce(0, +) > 0.99)
    #expect(columns[0].cards[0].heightShare != columns[0].cards[1].heightShare)
    #expect(columns[1].cards.map(\.heightShare) == [1])
  }

  @Test func tabbedColumnShowsItsWindowsAsEquallySizedCards() throws {
    let fixture = try ControllerFixture()
    _ = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.toggleTabbed)

    fixture.manager.perform(.toggleOverview)

    let column = try #require(fixture.overlays.overview?.snapshot.columns.first)
    #expect(column.cards.count == 2)
    #expect(Set(column.cards.map(\.heightShare)).count == 1)
  }

  @Test func overviewOfAnEmptyStripDoesNotOpen() throws {
    let fixture = try ControllerFixture()
    fixture.launch()

    fixture.manager.perform(.toggleOverview)

    #expect(fixture.overlays.overview == nil)
  }

  @Test func overviewOpensOnTheDisplayThatHoldsTheFocus() throws {
    let pair = [Display.leftOfPair, Display.rightOfPair]
    let fixture = try ControllerFixture(displays: pair)
    fixture.open(1, atX: 100, activating: true)
    fixture.open(2, atX: 1100)
    fixture.launch()
    fixture.manager.perform(.focusRight)

    fixture.manager.perform(.toggleOverview)

    let overview = try #require(fixture.overlays.overview)
    #expect(overview.displayFrame == Display.rightOfPair.frame)
    #expect(overview.snapshot.selection == WindowID(2))
  }

  @Test func moveCommandsChangeTheSelection() throws {
    let fixture = try ControllerFixture()
    _ = fixture.openRow(4)
    fixture.launch()
    fixture.manager.perform(.toggleOverview)

    fixture.overlays.press(.move(.right))
    #expect(selection(of: fixture) == WindowID(2))
    fixture.overlays.press(.move(.right))
    fixture.overlays.press(.move(.left))
    #expect(selection(of: fixture) == WindowID(2))
    fixture.overlays.press(.jump(4))
    #expect(selection(of: fixture) == WindowID(4))
    fixture.overlays.press(.jump(1))
    #expect(selection(of: fixture) == WindowID(1))
    fixture.overlays.press(.jump(9))
    #expect(selection(of: fixture) == WindowID(4))
  }

  @Test func verticalMovesStayInsideTheStackAndKeepTheRowAcrossColumns() throws {
    let fixture = try ControllerFixture()
    _ = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.toggleOverview)
    #expect(selection(of: fixture) == WindowID(2))

    fixture.overlays.press(.move(.up))
    #expect(selection(of: fixture) == WindowID(1))
    fixture.overlays.press(.move(.up))
    #expect(selection(of: fixture) == WindowID(1))
    fixture.overlays.press(.move(.down))
    fixture.overlays.press(.move(.right))
    #expect(selection(of: fixture) == WindowID(3))
  }

  @Test func confirmFocusesTheSelectedWindowScrollsItIntoViewAndHidesTheOverview() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    fixture.manager.perform(.toggleOverview)
    fixture.overlays.press(.jump(4))

    fixture.overlays.press(.confirm)

    var expected = ExpectedStrip(columns: [1, 2, 3, 4])
    expected.focus(4)
    let focused = try #require(row[3].frame)
    #expect(fixture.overlays.overview == nil)
    #expect(row[3].focusCount == 1)
    #expect(fixture.display.visibleFrame.contains(focused))
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(fixture.windowShowingFocusBorder(among: row) === row[3])
  }

  @Test func clickingACardFocusesThatWindowAndHidesTheOverview() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    fixture.manager.perform(.toggleOverview)

    fixture.overlays.click(WindowID(3))

    var expected = ExpectedStrip(columns: [1, 2, 3, 4])
    expected.focus(3)
    #expect(fixture.overlays.overview == nil)
    #expect(row[2].focusCount == 1)
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func confirmOnTheAlreadyFocusedWindowStillClosesAndActivatesIt() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.toggleOverview)

    fixture.overlays.press(.confirm)

    #expect(fixture.overlays.overview == nil)
    #expect(row[0].focusCount == 1)
  }

  @Test func dismissingChangesNothing() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    let before = fixture.frames(of: row)
    let border = fixture.overlays.focusBorder

    fixture.manager.perform(.toggleOverview)
    fixture.overlays.press(.jump(3))
    fixture.overlays.press(.dismiss)

    #expect(fixture.overlays.overview == nil)
    #expect(row.allSatisfy { $0.focusCount == 0 })
    #expect(fixture.frames(of: row) == before)
    #expect(fixture.overlays.focusBorder == border)
  }

  @Test func clickingTheBackdropAndTogglingAgainBothCloseWithoutChange() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    let before = fixture.frames(of: row)

    fixture.manager.perform(.toggleOverview)
    fixture.overlays.clickBackdrop()
    #expect(fixture.overlays.overview == nil)

    fixture.manager.perform(.toggleOverview)
    fixture.overlays.press(.move(.right))
    fixture.manager.perform(.toggleOverview)
    #expect(fixture.overlays.overview == nil)
    #expect(row.allSatisfy { $0.focusCount == 0 })
    #expect(fixture.frames(of: row) == before)
  }

  @Test func inputAfterClosingIsIgnored() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.toggleOverview)
    fixture.overlays.press(.dismiss)

    fixture.overlays.press(.confirm)
    fixture.overlays.click(WindowID(3))

    #expect(fixture.overlays.overview == nil)
    #expect(row.allSatisfy { $0.focusCount == 0 })
  }

  @Test func openingNeverReadsWindowTitles() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    let readsAfterAdmission = row.map(\.titleReadCount)

    fixture.manager.perform(.toggleOverview)
    fixture.overlays.press(.move(.right))
    fixture.overlays.press(.confirm)

    #expect(row.map(\.titleReadCount) == readsAfterAdmission)
    #expect(readsAfterAdmission == [1, 1, 1])
  }
}
