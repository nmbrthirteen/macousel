import CoreGraphics
import Testing

@testable import StripCore

struct StripLayoutTests {
  let config = LayoutConfig()

  @Test func twoHalfColumnsFillUsableWidthExactly() {
    var strip = makeStrip(2)
    strip.focusFirst()
    let layout = strip.layout(in: testViewport, config: config)
    #expect(layout[id(1)]?.frame == CGRect(x: 8, y: 8, width: 496, height: 800))
    #expect(layout[id(2)]?.frame == CGRect(x: 512, y: 8, width: 496, height: 800))
    #expect(layout.contentWidth == 1000)
  }

  @Test func threeThirdColumnsFillUsableWidthExactly() {
    var strip = Strip()
    for value in 1...3 as ClosedRange<UInt32> {
      strip.insert(id(value), config: LayoutConfig(defaultWidth: 1.0 / 3.0))
    }
    let layout = strip.layout(in: testViewport, config: config)
    #expect(widths(layout) == [328, 328, 328])
    #expect(layout.placements.last?.frame.maxX == 1008)
    #expect(layout.contentWidth == 1000)
  }

  @Test func fullWidthFixedAndOversizedFixedWidths() {
    var strip = makeStrip(3)
    strip.toggleFullWidth()
    strip.setFixedWidth(300, of: id(1))
    strip.setFixedWidth(5000, of: id(2))
    let layout = strip.layout(in: testViewport, config: config)
    #expect(widths(layout) == [300, 1000, 1000])
  }

  @Test func contentWidthSumsWidthsAndGaps() {
    var strip = makeStrip(3)
    strip.setFixedWidth(100, of: id(1))
    strip.setFixedWidth(200, of: id(2))
    strip.setFixedWidth(300, of: id(3))
    #expect(strip.contentWidth(viewportWidth: 1016, config: config) == 100 + 200 + 300 + 16)
    #expect(Strip().contentWidth(viewportWidth: 1016, config: config) == 0)
  }

  @Test func scrollOffsetShiftsFramesAndOverrideWins() {
    var strip = makeStrip(2)
    strip.scrollOffset = 100
    let own = strip.layout(in: testViewport, config: config)
    #expect(own[id(1)]?.frame.minX == -92)
    let override = strip.layout(in: testViewport, config: config, scrollOffset: 0)
    #expect(override[id(1)]?.frame.minX == 8)
    #expect(strip.scrollOffset == 100)
  }

  @Test func viewportOriginIsRespected() {
    let strip = makeStrip(1)
    let layout = strip.layout(
      in: CGRect(x: 200, y: 50, width: 1016, height: 816), config: config)
    #expect(layout[id(1)]?.frame == CGRect(x: 208, y: 58, width: 496, height: 800))
  }

  @Test func singleWindowColumnUsesFullHeight() {
    let layout = makeStrip(1).layout(in: testViewport, config: config)
    #expect(layout[id(1)]?.frame.height == 800)
    #expect(layout[id(1)]?.frame.minY == 8)
  }

  @Test func stackedRowsShareHeightByWeightWithGaps() {
    var strip = makeStrip(2)
    strip.stackFocused(into: .left)
    let layout = strip.layout(in: testViewport, config: config)
    let first = layout[id(1)]?.frame
    let second = layout[id(2)]?.frame
    #expect(first == CGRect(x: 8, y: 8, width: 496, height: 396))
    #expect(second == CGRect(x: 8, y: 412, width: 496, height: 396))
  }

  @Test func stackedRowsFollowWeightsAndFillColumnExactly() {
    var strip = makeStack(3)
    strip.focus(id(1))
    strip.adjustHeight(by: 0.2)
    let layout = strip.layout(in: testViewport, config: config)
    let frames = [id(1), id(2), id(3)].compactMap { layout[$0]?.frame }
    #expect(frames.count == 3)
    #expect(frames[0].height > frames[1].height)
    #expect(frames[0].minY == 8)
    #expect(frames[2].maxY == 808)
    #expect(frames[1].minY - frames[0].maxY == 8)
    #expect(frames[2].minY - frames[1].maxY == 8)
  }

  @Test func tabbedColumnSharesOneFrameBelowTabBar() {
    var strip = makeStrip(3)
    strip.focus(id(2))
    strip.stackFocused(into: .left)
    strip.toggleTabbed()
    strip.focus(id(1))
    let layout = strip.layout(in: testViewport, config: config)
    let expected = CGRect(x: 8, y: 36, width: 496, height: 772)
    #expect(layout[id(1)]?.frame == expected)
    #expect(layout[id(2)]?.frame == expected)
    #expect(layout[id(1)]?.isBehindTab == false)
    #expect(layout[id(2)]?.isBehindTab == true)
    #expect(layout[id(3)]?.isBehindTab == false)
  }

  @Test func rowAndColumnIndicesAndFocusFlags() {
    var strip = makeStrip(3)
    strip.focus(id(2))
    strip.stackFocused(into: .left)
    let layout = strip.layout(in: testViewport, config: config)
    #expect(layout[id(1)]?.column == 0 && layout[id(1)]?.row == 0)
    #expect(layout[id(2)]?.column == 0 && layout[id(2)]?.row == 1)
    #expect(layout[id(3)]?.column == 1 && layout[id(3)]?.row == 0)
    #expect(layout.placements.filter(\.isFocused).map(\.window) == [id(2)])
    #expect(layout[id(42)] == nil)
  }

  struct VisibilityCase: CustomTestStringConvertible {
    var offset: Double
    var expected: [Placement.Visibility]
    var testDescription: String { "offset \(offset)" }
  }

  @Test(arguments: [
    VisibilityCase(offset: 0, expected: [.full, .full, .partial]),
    VisibilityCase(offset: 250, expected: [.partial, .full, .full]),
    VisibilityCase(offset: 600, expected: [.offscreen(.left), .partial, .full]),
    VisibilityCase(offset: 1500, expected: [.offscreen(.left), .offscreen(.left), .offscreen(.left)]),
    VisibilityCase(offset: -1100, expected: [.offscreen(.right), .offscreen(.right), .offscreen(.right)]),
  ])
  func visibilityClassification(testCase: VisibilityCase) {
    var strip = makeStrip(3)
    for value in 1...3 as ClosedRange<UInt32> { strip.setFixedWidth(400, of: id(value)) }
    let layout = strip.layout(in: testViewport, config: config, scrollOffset: testCase.offset)
    #expect(layout.placements.map(\.visibility) == testCase.expected)
  }

  @Test func frameTouchingViewportEdgeIsOffscreen() {
    var strip = makeStrip(3)
    strip.setFixedWidth(1000, of: id(1))
    let layout = strip.layout(in: testViewport, config: config, scrollOffset: 1008)
    #expect(layout[id(1)]?.visibility == .offscreen(.left))
  }
}
