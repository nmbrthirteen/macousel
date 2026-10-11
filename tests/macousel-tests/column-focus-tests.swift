import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ColumnFocusTests {
  @Test func focusColumn3FocusesAndScrollsToTheThirdColumn() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()

    fixture.manager.perform(.focusColumn3)

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

    fixture.manager.perform(.focusColumn3)

    #expect(row.allSatisfy { $0.focusCount == 0 })
    #expect(fixture.frames(of: row) == before)
  }

  @Test func focusColumn1ReturnsToTheFirstColumn() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    fixture.manager.perform(.focusLast)

    fixture.manager.perform(.focusColumn1)

    #expect(row[0].focusCount == 1)
  }

  @Test func columnActionsMapToTheirZeroBasedIndex() {
    let indexes = Action.allCases.compactMap(\.columnIndex)
    #expect(indexes == Array(0..<9))
    #expect(Action.focusColumn3.commandName == "focus-column-3")
    #expect(Action.focusColumn3.title == "Focus column 3")
  }

  @Test func columnShortcutsUsePlainOptionAndTheDigit() {
    for action in Action.columnActions {
      let keys = Action.defaultShortcuts[action] ?? []
      #expect(keys.count == 1)
      #expect(keys.allSatisfy { $0.modifiers == [.option] })
    }
  }
}
