import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct TabTitleTests {
  private func tabbedPair() throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    return (fixture, row)
  }

  @Test func tabTitlesAreReadWhenTheColumnBecomesTabbed() throws {
    let (fixture, row) = try tabbedPair()
    let before = row.map(\.titleReadCount)

    fixture.manager.perform(.toggleTabbed)

    #expect(row[0].titleReadCount == before[0] + 1)
    #expect(row[1].titleReadCount == before[1] + 1)
    #expect(fixture.overlays.tabBars.first?.tabs.map(\.title) == ["Window 1", "Window 2"])
  }

  @Test func laterCommandsDoNotReadTabTitlesAgain() throws {
    let (fixture, row) = try tabbedPair()
    fixture.manager.perform(.toggleTabbed)
    let before = row.map(\.titleReadCount)

    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.focusLeft)

    #expect(row.map(\.titleReadCount) == before)
  }
}
