import Testing

@testable import StripCore

struct StripDirectAccessTests {
  @Test func focusColumnSelectsTheColumnAtTheIndex() {
    var strip = makeStrip(3)

    let moved = strip.focusColumn(0)

    #expect(moved)
    #expect(strip.focusedColumn == 0)
    #expect(strip.focusedWindow == id(1))
  }

  @Test func focusColumnReportsNoChangeForTheFocusedColumn() {
    var strip = makeStrip(3)

    let moved = strip.focusColumn(2)

    #expect(!moved)
  }

  @Test(arguments: [-1, 3, 40])
  func focusColumnIgnoresIndexesOutOfRange(index: Int) {
    var strip = makeStrip(3)

    let moved = strip.focusColumn(index)

    #expect(!moved)
    #expect(strip.focusedColumn == 2)
  }

  @Test func setFullWidthMarksOnlyTheColumnOfThatWindow() {
    var strip = makeStrip(3)

    strip.setFullWidth(true, of: id(2))

    #expect(strip.columns.map(\.isFullWidth) == [false, true, false])
    strip.setFullWidth(false, of: id(2))
    #expect(strip.columns.map(\.isFullWidth) == [false, false, false])
  }

  @Test func setFullWidthIgnoresAMissingWindow() {
    var strip = makeStrip(2)
    let before = strip

    strip.setFullWidth(true, of: id(9))

    #expect(strip == before)
  }

  @Test func aFullWidthColumnFillsTheUsableWidth() {
    var strip = makeStrip(2)
    let config = LayoutConfig()

    strip.setFullWidth(true, of: id(1))

    let layout = strip.layout(in: testViewport, config: config)
    let width = Double(layout.placements[0].frame.width)
    let usable = Double(testViewport.width) - 2 * config.outerGap
    #expect(width == usable)
  }
}
