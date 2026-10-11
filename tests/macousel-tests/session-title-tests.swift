import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct SessionTitleTests {
  @Test func theSessionSavesTheTitleCapturedWhenTheWindowWasAdmitted() throws {
    let suite = try IsolatedDefaults()
    let fixture = try ControllerFixture(suite: suite)
    let notes = fixture.open(1, app: .editor, title: "Notes", atX: 100, activating: true)
    fixture.launch()
    notes.title = "Renamed later"

    fixture.quit()

    let saved = SessionStore(defaults: suite.defaults).load()
    let titles = saved.values.flatMap { $0 }.flatMap(\.windows).map(\.title)
    #expect(titles == ["Notes"])
  }

  @Test func savingTheSessionDoesNotReadWindowTitlesAgain() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    let readsAfterAdmission = row.map(\.titleReadCount)

    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.moveLeft)
    fixture.quit()

    #expect(row.map(\.titleReadCount) == readsAfterAdmission)
    #expect(readsAfterAdmission == [1, 1, 1])
  }
}
