import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ColumnFocusTests {
  @Test func focusColumn3FocusesAndScrollsToTheThirdColumn() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()

    fixture.manager.perform(.focusColumn(3))

    var expected = ExpectedStrip(columns: [1, 2, 3, 4])
    expected.focus(3)
    #expect(row[2].focusCount == 1)
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(fixture.windowShowingFocusBorder(among: row) === row[2])
  }

  @Test func focusColumn3IsIgnoredWhenThereAreTwoColumns() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(2)
    fixture.launch()
    let before = fixture.frames(of: row)

    fixture.manager.perform(.focusColumn(3))

    #expect(row.allSatisfy { $0.focusCount == 0 })
    #expect(fixture.frames(of: row) == before)
  }

  @Test func focusColumn1ReturnsToTheFirstColumn() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    fixture.manager.perform(.focusLast)

    fixture.manager.perform(.focusColumn(1))

    #expect(row[0].focusCount == 1)
  }

  @Test func focusColumnNamesAndTitlesComeFromThePlace() {
    #expect(Action.focusColumn(3).commandName == "focus-column-3")
    #expect(Action.focusColumn(3).title == "Focus column 3")
    #expect(Action.focusColumn(9).title == "Focus column 9 (last)")
  }

  @Test func focusColumn9FocusesTheLastColumn() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()

    fixture.manager.perform(.focusColumn(9))

    #expect(row[3].focusCount == 1)
    #expect(fixture.windowShowingFocusBorder(among: row) === row[3])
  }

  @Test func focusColumn9FocusesTheLastColumnOfAShortStrip() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(2)
    fixture.launch()

    fixture.manager.perform(.focusColumn(9))

    #expect(row[1].focusCount == 1)
  }

  @Test func columnShortcutsUseControlOptionAndTheDigit() {
    for place in Action.places {
      let keys = Action.defaultShortcuts[.focusColumn(place)] ?? []
      #expect(keys.count == 1)
      #expect(keys.allSatisfy { $0.modifiers == [.control, .option] })
    }
  }
}
