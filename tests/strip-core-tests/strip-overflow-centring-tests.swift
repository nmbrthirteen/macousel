import CoreGraphics
import Testing

@testable import StripCore

struct StripOverflowCentringTests {
  private let config = LayoutConfig(centerMode: .onOverflow)

  private func strip(_ count: UInt32, width: Double? = nil) -> Strip {
    var strip = makeStrip(count, config: config)
    if let width {
      for value in 1...count { strip.setFixedWidth(width, of: id(value)) }
    }
    return strip
  }

  private func frames(of strip: Strip) -> [CGRect] {
    let layout = strip.layout(in: testViewport, config: config)
    return layout.placements.map(\.frame)
  }

  @Test func aLoneColumnSitsInTheMiddleOfTheScreen() {
    var strip = strip(1)
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    let frame = frames(of: strip)[0]
    #expect(abs(frame.midX - testViewport.midX) < 0.001)
  }

  @Test(arguments: [2, 3] as [UInt32])
  func aFittingStripIsCentredAsAWhole(count: UInt32) {
    var strip = strip(count, width: 250)
    strip.focus(id(1))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    let frames = frames(of: strip)
    let left = frames.map(\.minX).min() ?? 0
    let right = frames.map(\.maxX).max() ?? 0
    #expect(abs((left + right) / 2 - testViewport.midX) < 0.001)
  }

  @Test func aFittingStripStaysPutWhenTheFocusMoves() {
    var strip = strip(3, width: 250)
    strip.focus(id(1))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    let first = strip.scrollOffset
    strip.focus(id(3))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == first)
  }

  @Test func aTwoColumnPairIsASymmetricPair() {
    var strip = strip(2, width: 300)
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    let frames = frames(of: strip)
    #expect(abs((frames[0].minX - testViewport.minX) - (testViewport.maxX - frames[1].maxX)) < 0.001)
  }

  @Test(arguments: [1, 3, 5] as [UInt32])
  func anOverflowingStripCentresTheFocusedColumn(focused: UInt32) {
    var strip = strip(5, width: 400)
    strip.focus(id(focused))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    let frame = strip.layout(in: testViewport, config: config)[id(focused)]?.frame
    #expect(frame.map { abs($0.midX - testViewport.midX) < 0.001 } == true)
  }

  @Test func theFirstAndLastColumnsOfALongStripAreCentredToo() {
    var strip = strip(6, width: 400)
    strip.focusFirst()
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset < 0)
    strip.focusLast()
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    let content = strip.contentWidth(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset > content - 1000)
  }

  @Test func theModeMatchesAlwaysWhenTheStripOverflows() {
    var overflow = strip(5, width: 400)
    var always = overflow
    let alwaysConfig = LayoutConfig(centerMode: .always)
    for value in 1...5 as ClosedRange<UInt32> {
      overflow.focus(id(value))
      always.focus(id(value))
      overflow.scrollToFocus(viewportWidth: 1016, config: config)
      always.scrollToFocus(viewportWidth: 1016, config: alwaysConfig)
      #expect(overflow.scrollOffset == always.scrollOffset)
    }
  }
}
