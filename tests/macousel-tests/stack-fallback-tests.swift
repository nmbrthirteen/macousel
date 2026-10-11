import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct StackFallbackTests {
  private func launched(windows: CGWindowID) throws -> ControllerFixture {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    _ = fixture.openRow(windows)
    fixture.launch()
    return fixture
  }

  @Test func stackLeftFromTheFirstColumnStacksIntoTheNeighbourOnTheRight() throws {
    let fixture = try launched(windows: 3)
    fixture.manager.perform(.stackLeft)
    #expect(fixture.manager.position?.columnCount == 2)
    #expect(fixture.manager.position?.windowsInFocusedColumn == 2)
  }

  @Test func stackRightFromTheLastColumnStacksIntoTheNeighbourOnTheLeft() throws {
    let fixture = try launched(windows: 3)
    fixture.manager.perform(.focusLast)
    fixture.manager.perform(.stackRight)
    #expect(fixture.manager.position?.columnCount == 2)
    #expect(fixture.manager.position?.focusedIndex == 1)
    #expect(fixture.manager.position?.windowsInFocusedColumn == 2)
  }

  @Test func stackingWithASingleColumnDoesNothing() throws {
    let fixture = try launched(windows: 1)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.stackRight)
    #expect(fixture.manager.position?.columnCount == 1)
    #expect(fixture.manager.position?.windowsInFocusedColumn == 1)
  }

  @Test func theStackActionsHaveTheNewTitles() {
    #expect(Action.stackLeft.title == "Stack with the column on the left")
    #expect(Action.stackRight.title == "Stack with the column on the right")
    #expect(Action.stackLeft.rawValue == "stackLeft")
    #expect(Action.stackLeft.commandName == "stack-left")
  }
}
