import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct PlacementTests {
  private let pair = [Display.leftOfPair, Display.rightOfPair]

  private func windows(_ count: CGWindowID, in fixture: ControllerFixture) -> [FakeWindow] {
    (1...count).map { fixture.open($0, atX: CGFloat($0) * 100) }
  }

  @Test func framesReachingWindowsEqualTheEngineLayoutForTheViewport() throws {
    let fixture = try ControllerFixture()
    let open = windows(2, in: fixture)

    fixture.launch()

    let expected = ExpectedStrip(columns: [1, 2])
    #expect(fixture.frames(of: open) == expected.frames)
    #expect(expected.layout.placements.allSatisfy { $0.visibility == .full })
  }

  @Test func layoutFitsTheVisibleFrameBelowTheMenuBar() throws {
    let fixture = try ControllerFixture()
    let open = windows(1, in: fixture)

    fixture.launch()

    let frame = try #require(open[0].frame)
    let gap = CGFloat(fixture.config.outerGap)
    let visible = fixture.display.visibleFrame
    #expect(frame.minY == visible.minY + gap)
    #expect(frame.maxY == visible.maxY - gap)
  }

  @Test func columnPastTheRightEdgeParksWithAOnePointSliver() throws {
    let fixture = try ControllerFixture()
    let open = windows(3, in: fixture)

    fixture.launch()

    let parked = try #require(open[2].frame)
    #expect(parked.minX == fixture.display.frame.maxX - 1)
    #expect(parked.size == ExpectedStrip(columns: [1, 2, 3]).layout.placements[2].frame.size)
    #expect(fixture.frames(of: open) == ExpectedStrip(columns: [1, 2, 3]).frames)
  }

  @Test func columnsPastTheLeftEdgeParkWithAOnePointSliver() throws {
    let fixture = try ControllerFixture()
    let open = windows(4, in: fixture)
    fixture.launch()

    fixture.manager.perform(.focusLast)

    let parked = try #require(open[0].frame)
    #expect(parked.maxX == fixture.display.frame.minX + 1)
    var expected = ExpectedStrip(columns: [1, 2, 3, 4])
    expected.focus(4)
    #expect(fixture.frames(of: open) == expected.frames)
  }

  @Test func columnPastTheEdgeParksOnTheOppositeSideWhenADisplayIsNextToIt() throws {
    let fixture = try ControllerFixture(displays: pair)
    let open = windows(3, in: fixture)

    fixture.launch()

    let parked = try #require(open[2].frame)
    #expect(parked.maxX == Display.leftOfPair.frame.minX + 1)
    let expected = ExpectedStrip(columns: [1, 2, 3], on: .leftOfPair, among: pair)
    #expect(fixture.frames(of: open) == expected.frames)
  }

  @Test func columnOverhangingANeighbourByLessThanHalfStaysWhereTheEngineSetsIt() throws {
    let fixture = try ControllerFixture(displays: pair) { $0.layout.defaultWidth = 0.6 }
    let open = windows(2, in: fixture)

    fixture.launch()

    let expected = ExpectedStrip(columns: [1, 2], fraction: 0.6, on: .leftOfPair, among: pair)
    #expect(try #require(open[1].frame).maxX > Display.leftOfPair.frame.maxX)
    #expect(fixture.frames(of: open) == expected.frames)
  }

  @Test func columnOverhangingANeighbourByMoreThanHalfParksOnTheOppositeSide() throws {
    let fixture = try ControllerFixture(displays: pair) { $0.layout.defaultWidth = 0.9 }
    let open = windows(2, in: fixture)

    fixture.launch()

    let overhanging = try #require(open[1].frame)
    #expect(overhanging.maxX == Display.leftOfPair.frame.minX + 1)
  }

  @Test func partiallyVisibleColumnWithoutANeighbourStaysWhereTheEngineSetsIt() throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.6 }
    let open = windows(2, in: fixture)

    fixture.launch()

    let expected = ExpectedStrip(columns: [1, 2], fraction: 0.6)
    #expect(try #require(open[1].frame).maxX > fixture.display.frame.maxX)
    #expect(fixture.frames(of: open) == expected.frames)
  }

  @Test func unchangedFramesAreNotSubmittedAgain() throws {
    let fixture = try ControllerFixture()
    let open = windows(2, in: fixture)
    fixture.launch()
    let submitted = fixture.placer.submissions.count

    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.focusLeft)

    #expect(fixture.placer.submissions.count == submitted)
    #expect(open.allSatisfy { $0.framesSet.count == 1 })
  }
}
