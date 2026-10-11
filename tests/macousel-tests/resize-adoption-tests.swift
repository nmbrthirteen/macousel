import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ResizeAdoptionTests {
  private func launchedRow() throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.clock.advance(by: .milliseconds(300))
    return (fixture, row)
  }

  private func widened(_ window: FakeWindow, to width: CGFloat) throws -> CGRect {
    var resized = try #require(window.frame)
    resized.size.width = width
    return resized
  }

  @Test func resizeToNearlyTheFullWidthMakesTheColumnFullWidth() async throws {
    let (fixture, row) = try launchedRow()
    let usable = 1000 - 2 * fixture.config.outerGap
    fixture.source.userResized(row[1], to: try widened(row[1], to: usable - 10))

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.setFullWidth(true, of: WindowID(2)) }
    #expect(await fixture.becomes { fixture.frames(of: row) == expected.frames })
  }

  @Test func focusRightScrollsCorrectlyAfterAFullWidthResize() async throws {
    let (fixture, row) = try launchedRow()
    let usable = 1000 - 2 * fixture.config.outerGap
    fixture.source.userResized(row[1], to: try widened(row[1], to: usable - 10))
    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.setFullWidth(true, of: WindowID(2)) }
    #expect(await fixture.becomes { fixture.frames(of: row) == expected.frames })

    fixture.manager.perform(.focusRight)
    expected.focus(2)
    #expect(fixture.frames(of: row) == expected.frames)
    fixture.manager.perform(.focusRight)
    expected.focus(3)
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func smallerResizeMakesTheColumnFixedAtThatWidth() async throws {
    let (fixture, row) = try launchedRow()
    let resized = try widened(row[1], to: try #require(row[1].frame).width + 100)
    fixture.source.userResized(row[1], to: resized)

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.setFixedWidth(resized.width, of: WindowID(2)) }
    #expect(await fixture.becomes { fixture.frames(of: row) == expected.frames })
  }

  @Test func resizeWhileTheButtonIsDownIsLeftToTheDragPath() async throws {
    let (fixture, row) = try launchedRow()
    let grabbed = try #require(row[1].frame)
    let resized = try widened(row[1], to: grabbed.width + 100)
    let session = try DragSession(row[1], in: fixture, atX: 0.99)

    session.resize(to: resized, pointerAt: CGPoint(x: resized.maxX - 2, y: resized.midY))
    fixture.source.userResized(row[1], to: resized)
    try await Task.sleep(for: .milliseconds(450))

    #expect(row[1].framesSet.count == 1)
    #expect(row[1].frame == resized)
    session.release()
    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.setFixedWidth(resized.width, of: WindowID(2)) }
    #expect(fixture.frames(of: row) == expected.frames)
  }

  @Test func eachFurtherResizeRestartsTheWait() async throws {
    let (fixture, row) = try launchedRow()
    let first = try widened(row[1], to: try #require(row[1].frame).width + 60)
    fixture.source.userResized(row[1], to: first)
    try await Task.sleep(for: .milliseconds(150))
    let second = try widened(row[1], to: first.width + 40)

    fixture.source.userResized(row[1], to: second)
    try await Task.sleep(for: .milliseconds(150))
    #expect(row[1].framesSet.count == 1)

    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.setFixedWidth(second.width, of: WindowID(2)) }
    #expect(await fixture.becomes { fixture.frames(of: row) == expected.frames })
  }

  @Test func resizeIsIgnoredWhileTheLayoutIsStillMoving() async throws {
    let (fixture, row) = try launchedRow()
    fixture.placer.isIdle = false
    fixture.source.userResized(row[1], to: try widened(row[1], to: 700))
    try await Task.sleep(for: .milliseconds(450))
    #expect(row[1].framesSet.count == 1)

    fixture.placer.isIdle = true
    var expected = ExpectedStrip(columns: [1, 2, 3], fraction: 0.25)
    expected.apply { $0.setFixedWidth(700, of: WindowID(2)) }
    #expect(await fixture.becomes { fixture.frames(of: row) == expected.frames })
  }

  @Test func resizeNotificationRightAfterOurOwnSizeRequestIsIgnored() async throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let row = fixture.openRow(3)
    fixture.launch()
    let resized = try widened(row[1], to: try #require(row[1].frame).width + 100)

    fixture.source.userResized(row[1], to: resized)
    try await Task.sleep(for: .milliseconds(450))

    #expect(row[1].framesSet.count == 1)
  }

  @Test func aWidthDifferenceAtTheThresholdIsLeftAlone() async throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.clock.advance(by: .milliseconds(300))
    let before = fixture.frames(of: row)
    let requested = try #require(row[0].frame).width

    fixture.source.userResized(row[0], to: try widened(row[0], to: requested - 24))
    fixture.source.userResized(row[2], to: try widened(row[2], to: try #require(row[2].frame).width + 100))

    #expect(await fixture.becomes { row[2].framesSet.count > 1 })
    #expect(row[0].framesSet.count == 1)
    #expect(row[1].frame == before[2])
  }

  @Test func aWidthDifferenceJustPastTheThresholdIsAdopted() async throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.clock.advance(by: .milliseconds(300))
    let requested = try #require(row[0].frame).width
    let resized = try widened(row[0], to: requested - 25)

    fixture.source.userResized(row[0], to: resized)

    var expected = ExpectedStrip(columns: [1, 2, 3])
    expected.apply { $0.setFixedWidth(resized.width, of: WindowID(1)) }
    #expect(await fixture.becomes { fixture.frames(of: row) == expected.frames })
  }

  @Test func twoHalfWidthColumnsStillFillTheUsableWidthWhenOneSnapsNarrower() async throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.clock.advance(by: .milliseconds(300))
    let usableRight = fixture.display.visibleFrame.maxX - fixture.config.outerGap
    let requested = try #require(row[0].frame).width

    fixture.source.userResized(row[0], to: try widened(row[0], to: requested - 7))
    fixture.source.userResized(row[2], to: try widened(row[2], to: try #require(row[2].frame).width + 100))

    #expect(await fixture.becomes { row[2].framesSet.count > 1 })
    #expect(try #require(row[1].frame).maxX == usableRight)
    #expect(row[0].framesSet.count == 1)
  }
}
