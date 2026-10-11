import CoreGraphics
import Testing

@testable import Macousel

@MainActor
struct MenuBarPillGeometryTests {
  private func makeGeometry(_ count: Int, focused: Int, windows: Int = 1) -> MenuBarPillGeometry? {
    MenuBarPillGeometry(
      position: StripPosition(
        columnCount: count, focusedIndex: focused, windowsInFocusedColumn: windows))
  }

  @Test(arguments: [(1, 3.0), (5, 23.0), (12, 58.0)])
  func widthIsPillsPlusGaps(count: Int, width: Double) throws {
    let geometry = try #require(makeGeometry(count, focused: 0))
    #expect(abs(geometry.size.width - width) < 0.001)
    #expect(geometry.pills.count == count)
    #expect(abs(geometry.size.height - MenuBarPillGeometry.imageHeight) < 0.001)
  }

  @Test func twelveColumnsStayWithinTheWidthBound() throws {
    let geometry = try #require(makeGeometry(12, focused: 6))
    let maximum = 12 * MenuBarPillGeometry.pillWidth + 11 * MenuBarPillGeometry.pillGap
    #expect(geometry.size.width <= maximum)
    #expect(geometry.pills.flatMap(\.segments).allSatisfy { $0.maxX <= geometry.size.width })
  }

  @Test func pillsAreSeparatedByTheGap() throws {
    let geometry = try #require(makeGeometry(5, focused: 2))
    for (left, right) in zip(geometry.pills, geometry.pills.dropFirst()) {
      let gap = right.segments[0].minX - left.segments[0].maxX
      #expect(abs(gap - MenuBarPillGeometry.pillGap) < 0.001)
    }
  }

  @Test(arguments: [0, 4])
  func theFocusedPillAtEitherEndIsTheOnlyFocusedOne(focused: Int) throws {
    let geometry = try #require(makeGeometry(5, focused: focused))
    #expect(geometry.pills.map(\.isFocused) == (0..<5).map { $0 == focused })
  }

  @Test func theFocusedPillIsTallerAndCentredVertically() throws {
    let geometry = try #require(makeGeometry(5, focused: 2))
    let focused = geometry.pills[2].segments[0]
    let resting = geometry.pills[0].segments[0]
    #expect(focused.height > resting.height)
    #expect(focused.midY == resting.midY)
    #expect(focused.maxY <= MenuBarPillGeometry.imageHeight)
    #expect(focused.minY >= 0)
  }

  @Test(arguments: [(2, 2), (3, 3), (6, 3)])
  func aStackedFocusedColumnShowsShortSegments(windows: Int, segments: Int) throws {
    let geometry = try #require(makeGeometry(4, focused: 1, windows: windows))
    let stack = geometry.pills[1].segments
    #expect(stack.count == segments)
    #expect(stack.allSatisfy { $0.height < MenuBarPillGeometry.focusedPillHeight })
    let total = stack.map(\.height).reduce(0, +) + Double(segments - 1) * MenuBarPillGeometry.segmentGap
    #expect(abs(total - MenuBarPillGeometry.focusedPillHeight) < 0.001)
    #expect(geometry.pills[0].segments.count == 1)
  }

  @Test func aSingleWindowColumnIsOnePill() throws {
    let geometry = try #require(makeGeometry(3, focused: 1))
    #expect(geometry.pills.allSatisfy { $0.segments.count == 1 })
  }

  @Test(arguments: [0, 13, 40])
  func pastTheLimitThereIsNoGeometry(count: Int) {
    #expect(geometry(count, focused: 0) == nil)
  }

  @Test func aFocusedIndexOutsideTheColumnsHasNoGeometry() {
    #expect(geometry(3, focused: 3) == nil)
    #expect(geometry(3, focused: -1) == nil)
  }
}
