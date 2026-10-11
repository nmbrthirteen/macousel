import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct DragResizeTests {
  private func stackedRow() throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    return (fixture, row)
  }

  private func stackedExpectation() -> ExpectedStrip {
    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.focus(2)
    expected.apply { $0.stackFocused(into: .left) }
    expected.focus(3)
    expected.apply { $0.stackFocused(into: .left) }
    return expected
  }

  @Test func bottomEdgeHeightChangeOnlyChangesTheRowBelow() throws {
    let (fixture, row) = try stackedRow()
    let before = fixture.frames(of: row)
    var resized = try #require(row[1].frame)
    resized.size.height += 40
    let session = try DragSession(row[1], in: fixture)

    session.resize(to: resized, pointerAt: CGPoint(x: resized.midX, y: resized.maxY - 2))
    session.release()

    var expected = stackedExpectation()
    let visibleHeight = expected.display.visibleFrame.height
    let config = expected.config
    expected.apply {
      $0.setHeight(
        resized.height, of: WindowID(2), borrowingFrom: .below, viewportHeight: visibleHeight,
        config: config)
    }
    #expect(before == stackedExpectation().frames)
    #expect(fixture.frames(of: row) == expected.frames)
    #expect(row[0].frame == before[1])
    #expect(fixture.overlays.dropPreviewHistory.isEmpty)
  }

  @Test func topEdgeHeightChangeBorrowsFromTheRowAbove() throws {
    let (fixture, row) = try stackedRow()
    let before = fixture.frames(of: row)
    var resized = try #require(row[1].frame)
    resized.origin.y -= 40
    resized.size.height += 40
    let session = try DragSession(row[1], in: fixture)

    session.resize(to: resized, pointerAt: CGPoint(x: resized.midX, y: resized.minY + 2))
    session.release()

    #expect(row[2].frame == before[3])
    let grownHeight = try #require(row[1].frame).height
    let shrunkHeight = try #require(row[0].frame).height
    #expect(grownHeight == (try #require(before[2])).height + 40)
    #expect(shrunkHeight == (try #require(before[1])).height - 40)
  }

  @Test func fixedWidthFromADragSurvivesADisplayResize() async throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    var resized = try #require(row[1].frame)
    resized.size.width += 100
    let session = try DragSession(row[1], in: fixture, atX: 0.99)
    session.resize(to: resized, pointerAt: CGPoint(x: resized.maxX - 2, y: resized.midY))
    session.release()

    fixture.environment.displays = [.fake(width: 1400)]
    fixture.environment.onDisplaysChanged?()

    let wider = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25, on: .fake(width: 1400))
    #expect(await fixture.becomes { row[0].frame?.width == wider.frame(of: 1)?.width })
    #expect(try #require(row[1].frame).width == resized.width)
  }
}
