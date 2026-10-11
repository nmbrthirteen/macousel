import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct SessionRestoreTests {
  private struct Entry {
    var id: CGWindowID
    var app: FakeApp
    var title: String
  }

  private let entries = [
    Entry(id: 1, app: .editor, title: "Notes"),
    Entry(id: 2, app: .browser, title: "Docs"),
    Entry(id: 3, app: .terminal, title: "Build"),
    Entry(id: 4, app: .editor, title: "Draft"),
    Entry(id: 5, app: .terminal, title: "Logs"),
  ]

  private func relaunchedWindows(
    in fixture: ControllerFixture, idOffset: CGWindowID, order: [Int]
  ) -> [String: FakeWindow] {
    var windows: [String: FakeWindow] = [:]
    for (position, index) in order.enumerated() {
      let entry = entries[index]
      windows[entry.title] = fixture.open(
        entry.id + idOffset, app: entry.app, title: entry.title, atX: CGFloat(position + 1) * 150)
    }
    return windows
  }

  private func firstSession(
    suite: IsolatedDefaults
  ) throws -> (frames: [String: CGRect], fixture: ControllerFixture) {
    let fixture = try ControllerFixture(suite: suite) { $0.layout.defaultWidth = 0.25 }
    var windows: [String: FakeWindow] = [:]
    for (index, entry) in entries.enumerated() {
      windows[entry.title] = fixture.open(
        entry.id, app: entry.app, title: entry.title, atX: CGFloat(index + 1) * 150,
        activating: index == 0)
    }
    fixture.launch()
    let steps: [Action] = [
      .focusRight, .focusRight, .stackLeft, .toggleTabbed,
      .focusRight, .focusRight, .stackLeft, .taller,
      .focusFirst, .cycleWidth,
    ]
    steps.forEach(fixture.manager.perform)
    return (windows.compactMapValues(\.frame), fixture)
  }

  @Test func columnsWidthsStacksTabsAndRowHeightsRestoreAfterARelaunch() throws {
    let suite = try IsolatedDefaults()
    let (arranged, first) = try firstSession(suite: suite)
    first.quit()

    let second = try ControllerFixture(suite: suite) { $0.layout.defaultWidth = 0.25 }
    let windows = relaunchedWindows(in: second, idOffset: 10, order: [4, 2, 0, 3, 1])
    second.launch()

    #expect(windows.compactMapValues(\.frame) == arranged)
    #expect(Set(arranged.values).count == 4)
    #expect(second.overlays.tabBars.count == 1)
    #expect(second.overlays.tabBars.first?.tabs.map(\.title).sorted() == ["Build", "Docs"])
  }

  @Test func relaunchedWindowsAreMatchedByAppAndTitleNotByPosition() throws {
    let suite = try IsolatedDefaults()
    let (arranged, first) = try firstSession(suite: suite)
    first.quit()

    let second = try ControllerFixture(suite: suite) { $0.layout.defaultWidth = 0.25 }
    let windows = relaunchedWindows(in: second, idOffset: 20, order: [0, 1, 2, 3, 4].reversed())
    second.launch()

    #expect(windows.compactMapValues(\.frame) == arranged)
  }

  @Test func windowsMissingFromTheSavedSessionAreAppendedAfterTheRestoredColumns() throws {
    let suite = try IsolatedDefaults()
    let saved = try ControllerFixture(suite: suite) { $0.layout.defaultWidth = 0.25 }
    saved.open(1, app: .editor, title: "Notes", atX: 100, activating: true)
    saved.open(2, app: .browser, title: "Docs", atX: 400)
    saved.launch()
    saved.manager.perform(.cycleWidth)
    saved.quit()

    let second = try ControllerFixture(suite: suite) { $0.layout.defaultWidth = 0.25 }
    let stray = second.open(9, app: .terminal, title: "Stray", atX: 10)
    let notes = second.open(11, app: .editor, title: "Notes", atX: 300)
    let docs = second.open(12, app: .browser, title: "Docs", atX: 600)
    second.launch()

    var expected = ExpectedStrip(columns: [11, 12, 9], fraction: 0.25)
    let config = expected.config
    expected.focus(11)
    expected.strip.cycleWidth(config: config)
    #expect(second.frames(of: [notes, docs, stray]) == expected.frames)
  }

  @Test func sessionIsIgnoredWhenRestoringIsTurnedOff() throws {
    let suite = try IsolatedDefaults()
    let saved = try ControllerFixture(suite: suite) { $0.layout.defaultWidth = 0.25 }
    saved.open(1, app: .editor, title: "Notes", atX: 100, activating: true)
    saved.open(2, app: .browser, title: "Docs", atX: 400)
    saved.launch()
    saved.manager.perform(.cycleWidth)
    saved.quit()

    let second = try ControllerFixture(suite: suite) {
      $0.layout.defaultWidth = 0.25
      $0.restoresSession = false
    }
    let docs = second.open(12, app: .browser, title: "Docs", atX: 100)
    let notes = second.open(11, app: .editor, title: "Notes", atX: 400)
    second.launch()

    let expected = ExpectedStrip(columns: [12, 11], fraction: 0.25)
    #expect(second.frames(of: [docs, notes]) == expected.frames)
  }

  @Test func sessionIsSavedWhenQuitting() throws {
    let suite = try IsolatedDefaults()
    let fixture = try ControllerFixture(suite: suite)
    _ = fixture.openRow(2)
    fixture.launch()
    #expect(suite.defaults.data(forKey: "session") == nil)

    fixture.quit()

    #expect(suite.defaults.data(forKey: "session") != nil)
  }
}
