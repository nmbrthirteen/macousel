import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DragLoggingTests {
  private func launchedRow() throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    return (fixture, row)
  }

  private func drag(_ window: FakeWindow, to point: CGPoint, in fixture: ControllerFixture) throws {
    let grabbed = try #require(window.frame)
    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.midX, y: grabbed.midY))
    fixture.pointer.moveTo(point)
    fixture.source.userMoved(
      window, to: grabbed.offsetBy(dx: point.x - grabbed.midX, dy: point.y - grabbed.midY))
    fixture.pointer.releasePrimary()
  }

  @Test func aRecognisedDragLogsItsWindow() async throws {
    let log = RecordedLog()
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)
    try drag(row[0], to: CGPoint(x: target.midX, y: target.minY + 10), in: fixture)
    #expect(try await log.messages(category: "drag").contains("drag recognised: window 1"))
  }

  @Test func aStackLogsTheBranchWithoutAPointerPosition() async throws {
    let log = RecordedLog()
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)
    try drag(row[0], to: CGPoint(x: target.midX, y: target.minY + 10), in: fixture)
    #expect(try await log.messages(category: "drag").contains("drag ended: window 1 stacked above a target"))
  }

  @Test func aMissedStackLogsHowFarTheDropWasFromTheMiddle() async throws {
    let log = RecordedLog()
    let (fixture, row) = try launchedRow()
    let target = try #require(row[2].frame)
    try drag(row[0], to: CGPoint(x: target.minX + 5, y: target.midY), in: fixture)
    let fraction = Double(5 / target.width)
    let text = fraction.formatted(.number.precision(.fractionLength(2)))
    let expected =
      "drag ended: window 1 reordered to column 2, pointer at \(text) of the window under it"
    #expect(try await log.messages(category: "drag").contains(expected))
  }

  @Test func aDropOverNoWindowSaysSo() async throws {
    let log = RecordedLog()
    let (fixture, row) = try launchedRow()
    let grabbed = try #require(row[0].frame)
    try drag(row[0], to: CGPoint(x: 950, y: grabbed.midY), in: fixture)
    let expected = "drag ended: window 1 reordered to column 3, pointer over no window"
    #expect(try await log.messages(category: "drag").contains(expected))
  }

  @Test func aResizeLogsWhichEdgesChanged() async throws {
    let log = RecordedLog()
    let (fixture, row) = try launchedRow()
    let grabbed = try #require(row[1].frame)
    var resized = grabbed
    resized.size.width += 100
    fixture.pointer.pressPrimary(at: CGPoint(x: grabbed.maxX - 2, y: grabbed.midY))
    fixture.source.userResized(row[1], to: resized)
    fixture.pointer.releasePrimary()
    #expect(try await log.messages(category: "drag").contains("drag ended: window 2 resized width"))
  }

  @Test func aMoveThatIsNotADragLogsNothing() async throws {
    let log = RecordedLog()
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let window = fixture.open(777, atX: 100, activating: true)
    fixture.launch()
    let grabbed = try #require(window.frame)
    fixture.source.userMoved(window, to: grabbed.offsetBy(dx: 300, dy: 0))
    let messages = try await log.messages(category: "drag")
    #expect(!messages.contains { $0.contains("window 777") })
  }
}
