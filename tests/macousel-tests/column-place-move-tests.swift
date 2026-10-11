import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ColumnPlaceMoveTests {
  private func launchedRow(
    _ count: CGWindowID, focusing last: Bool = true
  ) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(count)
    fixture.launch()
    if last { fixture.manager.perform(.focusLast) }
    return (fixture, row)
  }

  private func expectedOrder(_ order: [CGWindowID], focusing focused: CGWindowID)
    -> ExpectedStrip
  {
    var expected = ExpectedStrip(columns: order)
    expected.focus(focused)
    return expected
  }

  @Test func moveToColumn1MakesTheFocusedWindowTheFirstColumn() throws {
    let (fixture, row) = try launchedRow(4)

    fixture.manager.perform(.moveToColumn(1))

    #expect(fixture.frames(of: row) == expectedOrder([4, 1, 2, 3], focusing: 4).frames)
  }

  @Test func moveToColumn3PutsTheFocusedWindowInThirdPlace() throws {
    let (fixture, row) = try launchedRow(4, focusing: false)

    fixture.manager.perform(.moveToColumn(3))

    #expect(fixture.frames(of: row) == expectedOrder([2, 3, 1, 4], focusing: 1).frames)
  }

  @Test func moveToColumn9SendsTheFocusedWindowToTheEnd() throws {
    let (fixture, row) = try launchedRow(4, focusing: false)

    fixture.manager.perform(.moveToColumn(9))

    #expect(fixture.frames(of: row) == expectedOrder([2, 3, 4, 1], focusing: 1).frames)
  }

  @Test func moveToAPlacePastTheEndDoesNothing() throws {
    let (fixture, row) = try launchedRow(3)
    let before = fixture.frames(of: row)

    fixture.manager.perform(.moveToColumn(5))

    #expect(fixture.frames(of: row) == before)
  }

  @Test func moveToFirstSendsTheFocusedWindowToTheStart() throws {
    let (fixture, row) = try launchedRow(4)

    fixture.manager.perform(.moveToFirst)

    #expect(fixture.frames(of: row) == expectedOrder([4, 1, 2, 3], focusing: 4).frames)
  }

  @Test func moveToLastSendsTheFocusedWindowToTheEnd() throws {
    let (fixture, row) = try launchedRow(4, focusing: false)

    fixture.manager.perform(.moveToLast)

    #expect(fixture.frames(of: row) == expectedOrder([2, 3, 4, 1], focusing: 1).frames)
  }

  @Test func moveToFirstOnTheFirstColumnChangesNothing() throws {
    let (fixture, row) = try launchedRow(3, focusing: false)
    let before = fixture.frames(of: row)

    fixture.manager.perform(.moveToFirst)

    #expect(fixture.frames(of: row) == before)
  }
}
