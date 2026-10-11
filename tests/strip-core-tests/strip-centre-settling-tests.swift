import Testing

@testable import StripCore

struct StripCentreSettlingTests {
  private func wideStrip(mode: CenterMode) -> (Strip, LayoutConfig) {
    let config = LayoutConfig(centerMode: mode)
    var strip = Strip()
    for value in 1...5 as ClosedRange<UInt32> {
      strip.insert(id(value), config: config)
      strip.setFixedWidth(400, of: id(value))
    }
    return (strip, config)
  }

  @Test(arguments: [CenterMode.onOverflow, .always])
  func centreModesFocusTheColumnNearestTheCentre(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.settle(at: 700, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(3))
    #expect(strip.scrollOffset == 516)
  }

  @Test(arguments: [CenterMode.onOverflow, .always])
  func centreModesRestWithTheFocusedColumnCentred(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.settle(at: 450, viewportWidth: 1016, config: config)
    let frame = strip.layout(in: testViewport, config: config)[strip.focusedWindow ?? id(1)]?.frame
    #expect(frame.map { abs($0.midX - testViewport.midX) < 0.001 } == true)
  }

  @Test(arguments: [CenterMode.onOverflow, .always])
  func centreModesCanRestOnTheFirstAndLastColumn(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.settle(at: -5000, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(1))
    #expect(strip.scrollOffset == 200 - 500)
    strip.settle(at: 9000, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(5))
    #expect(strip.scrollOffset == 1632 + 200 - 500)
  }

  @Test func onOverflowRecentresAFittingStripAsAWhole() {
    let config = LayoutConfig(centerMode: .onOverflow)
    var strip = makeStrip(3, config: config)
    for value in 1...3 as ClosedRange<UInt32> { strip.setFixedWidth(250, of: id(value)) }
    strip.settle(at: 300, viewportWidth: 1016, config: config)
    let spare = 1000 - strip.contentWidth(viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == -spare / 2)
    #expect(strip.focusedWindow == id(3))
  }

  @Test func neverStillRestsFlushOnALeftEdge() {
    var (strip, config) = wideStrip(mode: .never)
    strip.settle(at: 450, viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 408)
  }

  @Test(arguments: [CenterMode.never, .onOverflow, .always])
  func aShortSlowSwipeSnapsBackToTheStartingColumn(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.focus(id(2))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    let resting = strip.scrollOffset
    strip.settle(at: resting + 60, intent: .none, viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == resting)
    #expect(strip.focusedWindow == id(2))
  }

  @Test(arguments: [CenterMode.onOverflow, .always])
  func forwardIntentAdvancesOneColumnEvenWhenTheProjectionSnapsBack(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.focus(id(2))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    strip.settle(
      at: strip.scrollOffset + 60, intent: .forward, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(3))
  }

  @Test(arguments: [CenterMode.onOverflow, .always])
  func backwardIntentAdvancesOneColumnTowardTheStart(mode: CenterMode) {
    var (strip, config) = wideStrip(mode: mode)
    strip.focus(id(3))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    strip.settle(
      at: strip.scrollOffset - 60, intent: .backward, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(2))
  }

  @Test func forwardIntentAdvancesOneColumnInNeverMode() {
    var (strip, config) = wideStrip(mode: .never)
    strip.settle(at: 0, viewportWidth: 1016, config: config)
    strip.settle(at: 60, intent: .forward, viewportWidth: 1016, config: config)
    #expect(strip.scrollOffset == 408)
  }

  @Test func aLongThrowGoesAsFarAsTheProjection() {
    var (strip, config) = wideStrip(mode: .always)
    strip.focus(id(1))
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    strip.settle(at: 1100, intent: .forward, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(4))
  }

  @Test func intentDoesNotMoveBeyondTheLastColumn() {
    var (strip, config) = wideStrip(mode: .always)
    strip.focusLast()
    strip.scrollToFocus(viewportWidth: 1016, config: config)
    strip.settle(at: strip.scrollOffset + 60, intent: .forward, viewportWidth: 1016, config: config)
    #expect(strip.focusedWindow == id(5))
  }
}
