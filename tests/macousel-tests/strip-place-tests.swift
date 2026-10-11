import StripCore
import Testing

@testable import Macousel

@MainActor
struct StripPlaceTests {
  private let config = LayoutConfig()

  private func strip(windows count: UInt32) -> Strip {
    var strip = Strip()
    for value in 0..<count {
      strip.insert(WindowID(value + 1), config: config)
    }
    return strip
  }

  private func apply(_ action: Action, to strip: inout Strip) -> StripCommandOutcome {
    strip.apply(action, viewportWidth: 1016, config: config)
  }

  @Test func focusPlaceNineMeansTheLastColumn() {
    var strip = strip(windows: 5)
    strip.focusFirst()
    #expect(apply(.focusColumn(9), to: &strip) == .applied)
    #expect(strip.focusedColumn == 4)
  }

  @Test func focusPlaceEightPastTheEndIsIgnored() {
    var strip = strip(windows: 5)
    #expect(apply(.focusColumn(8), to: &strip) == .ignored)
  }

  @Test func movePlaceNineMeansTheLastColumn() {
    var strip = strip(windows: 4)
    strip.focusFirst()
    #expect(apply(.moveToColumn(9), to: &strip) == .applied)
    #expect(strip.columns.map(\.activeWindow) == [2, 3, 4, 1].map { WindowID($0) })
    #expect(strip.focusedColumn == 3)
  }

  @Test func movePlaceTakesAStackedWindowOutOfItsStack() {
    var strip = strip(windows: 3)
    strip.stackFocused(into: .left)
    #expect(strip.columns.count == 2)
    #expect(apply(.moveToColumn(1), to: &strip) == .applied)
    #expect(strip.columns.count == 3)
    #expect(strip.columns[0].windows == [WindowID(3)])
    #expect(strip.focusedColumn == 0)
  }

  @Test func aStackedWindowCanMoveToANewPlaceAtTheEnd() {
    var strip = strip(windows: 3)
    strip.stackFocused(into: .left)
    #expect(apply(.moveToColumn(3), to: &strip) == .applied)
    #expect(strip.columns.count == 3)
    #expect(strip.columns[2].windows == [WindowID(3)])
  }

  @Test func movingToTheFirstColumnKeepsAFirstWindowInPlace() {
    var strip = strip(windows: 3)
    strip.focusFirst()
    #expect(apply(.moveToFirst, to: &strip) == .ignored)
    #expect(apply(.moveToColumn(1), to: &strip) == .ignored)
  }
}
