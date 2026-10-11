import Testing

@testable import StripCore

struct StripSettlingTests {
  private func wideStrip(mode: CenterMode) -> (Strip, LayoutConfig) {
    let config = LayoutConfig(centerMode: mode)
    var strip = Strip()
    for value in 1...5 as ClosedRange<UInt32> {
      strip.insert(id(value), config: config)
      strip.setFixedWidth(400, of: id(value))
    }
    return (strip, config)
  }

  @Test(arguments: [CenterMode.never])
  func restsFlushOnTheNearestColumnLeftEdge(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.settle(at: 450, viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 408)
    strip.settle(at: 640, viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 816)
  }

  @Test(arguments: [CenterMode.never])
  func restsAtTheEndOfTheStripWhenThatIsNearest(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.settle(at: 1000, viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 1032)
    strip.settle(at: 9000, viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 1032)
  }

  @Test(arguments: [CenterMode.never])
  func restsAtTheStartWhenProjectedBeforeIt(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.settle(at: -2000, viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 0)
    #expect(strip.focusedWindow == id(1))
  }

  @Test(arguments: [CenterMode.never])
  func keepsFocusWhenTheFocusedColumnStaysFullyVisible(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.focus(id(3))
    strip.settle(at: 408, viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 408)
    #expect(strip.focusedWindow == id(3))
  }

  @Test(arguments: [CenterMode.never])
  func movesFocusToTheFirstFullyVisibleColumnWhenTheFocusedOneLeaves(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.focus(id(1))
    strip.settle(at: 816, viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 816)
    #expect(strip.focusedWindow == id(3))
  }

  @Test func ignoresAColumnThatIsOnlyPartlyVisibleWhenChoosingFocus() {
    var (strip, config) = wideStrip(mode: .never)
    strip.focus(id(1))
    strip.settle(at: 1032, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(4))
  }

  @Test func fallsBackToTheColumnNearestTheCentreWhenNoColumnFits() {
    var (strip, config) = wideStrip(mode: .never)
    for value in 1...5 as ClosedRange<UInt32> {
      strip.setFixedWidth(1200, of: id(value))
    }
    strip.settle(at: 0, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(1))
    strip.settle(at: 1208, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(2))
  }

  @Test func alwaysCentreModeStillFocusesTheColumnNearestTheCentre() {
    var (strip, config) = wideStrip(mode: .always)
    strip.settle(at: 700, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(3))
    #expect(strip.scrollOffset == 516)
  }

  @Test func fittingContentRestsAtTheStart() {
    var strip = makeStrip(2)
    strip.settle(at: 300, viewportWidth: 1016, config: LayoutConfig())
    #expect(strip.scrollOffset == 0)
  }
}
