import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct CommandLoggingTests {
  private func launched(windows: CGWindowID) throws -> ControllerFixture {
    let fixture = try ControllerFixture()
    _ = fixture.openRow(windows)
    fixture.launch()
    return fixture
  }

  @Test func aPerformedActionLogsItsOutcomeShapeAndFocus() async throws {
    let log = RecordedLog()
    let fixture = try launched(windows: 3)
    fixture.manager.perform(.focusRight)
    let messages = try await log.messages(category: "commands")
    #expect(messages.contains("focus-right applied: 1,1,1 -> 1,1,1, focus 0 -> 1"))
  }

  @Test func aStackLogsTheShapeBeforeAndAfter() async throws {
    let log = RecordedLog()
    let fixture = try launched(windows: 3)
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    let messages = try await log.messages(category: "commands")
    #expect(messages.contains("stack-left applied: 1,1,1 -> 2,1, focus 1 -> 0"))
  }

  @Test func anEdgeLogsTheBlockedSide() async throws {
    let log = RecordedLog()
    let fixture = try launched(windows: 2)
    fixture.manager.perform(.focusLeft)
    let messages = try await log.messages(category: "commands")
    #expect(messages.contains("focus-left blocked at left edge: 1,1 -> 1,1, focus 0 -> 0"))
  }

  @Test func anActionWhilePausedLogsWhyItWasDropped() async throws {
    let log = RecordedLog()
    let fixture = try launched(windows: 2)
    fixture.manager.perform(.togglePaused)
    fixture.manager.perform(.focusRight)
    let messages = try await log.messages(category: "commands")
    #expect(messages.contains("focus-right dropped: tiling is paused"))
  }

  @Test func anActionWithoutAWorkspaceLogsWhyItWasDropped() async throws {
    let log = RecordedLog()
    let fixture = try ControllerFixture(displays: [])
    fixture.launch()
    fixture.manager.perform(.focusRight)
    let messages = try await log.messages(category: "commands")
    #expect(messages.contains("focus-right dropped: no active workspace"))
  }

  @Test func registeringShortcutsLogsTheCountsAndFailures() async throws {
    let log = RecordedLog()
    let fixture = try ControllerFixture()
    fixture.shortcuts.failureCount = 2
    fixture.launch()
    let messages = try await log.messages(category: "shortcuts")
    let expected = fixture.shortcuts.boundHotkeys.count - 2
    #expect(messages.contains("registered \(expected) shortcuts, 2 failed"))
  }
}
