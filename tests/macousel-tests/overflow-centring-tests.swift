import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct OverflowCentringTests {
  private func launched(windows: CGWindowID) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.centerMode = .onOverflow }
    let row = fixture.openRow(windows)
    fixture.launch()
    return (fixture, row)
  }

  private func isCentred(_ window: FakeWindow, in fixture: ControllerFixture) -> Bool {
    guard let frame = window.frame else { return false }
    return abs(frame.midX - fixture.display.visibleFrame.midX) < 1
  }

  @Test func aLoneColumnSitsInTheMiddle() throws {
    let (fixture, row) = try launched(windows: 1)
    #expect(isCentred(row[0], in: fixture))
  }

  @Test func aLoneColumnStaysCentredAfterANavigationCommand() throws {
    let (fixture, row) = try launched(windows: 1)
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.focusFirst)
    #expect(isCentred(row[0], in: fixture))
  }

  @Test func aFittingPairIsCentredAsAPair() throws {
    let (fixture, row) = try launched(windows: 2)
    fixture.manager.perform(.focusRight)
    let visible = fixture.display.visibleFrame
    let first = try #require(row[0].frame)
    let second = try #require(row[1].frame)
    #expect(abs((first.minX - visible.minX) - (visible.maxX - second.maxX)) < 1)
    fixture.manager.perform(.focusLeft)
    #expect(abs((first.minX - visible.minX) - (visible.maxX - second.maxX)) < 1)
  }

  @Test func eachColumnOfALongStripIsCentredWhenFocused() throws {
    let (fixture, row) = try launched(windows: 6)
    fixture.manager.perform(.focusFirst)
    #expect(isCentred(row[0], in: fixture))
    for index in 1..<row.count {
      fixture.manager.perform(.focusRight)
      #expect(isCentred(row[index], in: fixture))
    }
    fixture.manager.perform(.focusLast)
    #expect(isCentred(row[5], in: fixture))
  }

  @Test func centringMatchesTheEngineRule() throws {
    let (fixture, row) = try launched(windows: 6)
    fixture.manager.perform(.focusFirst)
    var expected = ExpectedStrip(columns: [1, 2, 3, 4, 5, 6])
    expected.config = fixture.config
    expected.focus(1)
    #expect(fixture.frames(of: row) == expected.frames)
  }
}
