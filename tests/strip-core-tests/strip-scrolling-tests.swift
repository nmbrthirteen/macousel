import CoreGraphics
import Testing

@testable import StripCore

struct StripScrollingTests {
  private func wideStrip(mode: CenterMode) -> (Strip, LayoutConfig) {
    let config = LayoutConfig(centerMode: mode)
    var strip = Strip()
    for value in 1...5 as ClosedRange<UInt32> {
      strip.insert(id(value), config: config)
      strip.setFixedWidth(400, of: id(value))
    }
    return (strip, config)
  }

  @Test func neverScrollsMinimumDistanceToRevealFocus() {
    let (strip, config) = wideStrip(mode: .never)
    var scrolled = strip
    scrolled.focusFirst()
    scrolled.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(scrolled.scrollOffset == 0)

    scrolled.focus(id(3))
    scrolled.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(scrolled.scrollOffset == 816 + 400 - 1000)

    scrolled.focus(id(2))
    scrolled.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(scrolled.scrollOffset == 216)

    scrolled.focus(id(1))
    scrolled.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(scrolled.scrollOffset == 0)

    scrolled.focus(id(5))
    scrolled.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(scrolled.scrollOffset == 1032)
  }

  @Test func neverLeavesOffsetAloneWhenFocusAlreadyVisible() {
    var (strip, config) = wideStrip(mode: .never)
    strip.focus(id(2))
    strip.scrollOffset = 300
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 300)
  }

  @Test func neverClampsToContentBounds() {
    var (strip, config) = wideStrip(mode: .never)
    strip.scrollOffset = -500
    strip.focus(id(1))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 0)
    strip.scrollOffset = 5000
    strip.focus(id(5))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 1032)
  }

  @Test(arguments: CenterMode.allCases)
  func fittingContent(mode: CenterMode) {
    let config = LayoutConfig(centerMode: mode)
    var strip = makeStrip(2, config: config)
    strip.scrollOffset = 77
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    switch mode {
    case .never, .onOverflow:
      #expect(strip.scrollOffset == 0)
    case .always:
      #expect(strip.scrollOffset == 752 - 500)
    }
  }

  @Test func onOverflowCentresAndClamps() {
    var (strip, config) = wideStrip(mode: .onOverflow)
    strip.focus(id(3))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 816 + 200 - 500)
    strip.focus(id(1))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 0)
    strip.focus(id(5))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 1032)
  }

  @Test func alwaysCentresWithoutClamping() {
    var (strip, config) = wideStrip(mode: .always)
    strip.focus(id(1))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 200 - 500)
    strip.focus(id(5))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 1632 + 200 - 500)
  }

  @Test(arguments: CenterMode.allCases)
  func centerFocusedIgnoresModeAndClamping(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.focus(id(1))
    strip.centerFocused(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == -300)
  }

  @Test func focusedColumnIsCentredOnScreenAfterCentering() {
    var (strip, config) = wideStrip(mode: .always)
    strip.focus(id(3))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    let frame = strip.layout(in: CGRect(x: 0, y: 0, width: 1016, height: 816), config: config)[id(3)]?.frame
    #expect(frame?.midX == 508)
  }

  @Test func scrollingOnEmptyStripIsHarmless() {
    var strip = Strip()
    strip.scrollOffset = 50
    strip.scrollToFocus(viewportWidth: 1016, config: LayoutConfig())
    #expect(strip.scrollOffset == 0)
    strip.centerFocused(viewportWidth: 1016, config: LayoutConfig())
    strip.settle(at: 30, viewportWidth: 1016, config: LayoutConfig())
    #expect(strip.scrollOffset == 0)
    #expect(strip.focusedColumn == nil)
  }

  @Test func settleFocusesColumnNearestViewportCentre() {
    var (strip, config) = wideStrip(mode: .never)
    strip.settle(at: 700, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(3))
    strip.settle(at: 0, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(2))
    #expect(strip.scrollOffset == 0)
  }

  @Test func settleAppliesCenterModeToWinner() {
    var (strip, config) = wideStrip(mode: .onOverflow)
    strip.settle(at: 700, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(3))
    #expect(strip.scrollOffset == 516)
  }

  @Test func settleBeyondEndsPicksEdgeColumns() {
    var (strip, config) = wideStrip(mode: .never)
    strip.settle(at: -2000, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(1))
    strip.settle(at: 9000, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(5))
    #expect(strip.scrollOffset == 1032)
  }
}
