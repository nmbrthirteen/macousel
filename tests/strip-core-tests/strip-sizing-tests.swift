import Testing

@testable import StripCore

struct StripSizingTests {
  let config = LayoutConfig()

  @Test(arguments: [
    (start: 0.25, expected: 1.0 / 3.0),
    (start: 0.5, expected: 2.0 / 3.0),
    (start: 0.75, expected: 0.25),
    (start: 0.6, expected: 2.0 / 3.0),
    (start: 0.9, expected: 0.25),
  ])
  func cycleWidthPicksNextLargerPresetAndWraps(start: Double, expected: Double) {
    var strip = makeStrip(1)
    strip.columns[0].width = .fraction(start)
    let moved = strip.cycleWidth(config: config)
    #expect(moved)
    #expect(strip.columns[0].width == .fraction(expected))
  }

  @Test func cycleWidthClearsFullWidthAndWraps() {
    var strip = makeStrip(1)
    strip.toggleFullWidth()
    strip.cycleWidth(config: config)
    #expect(!strip.columns[0].isFullWidth)
    #expect(strip.columns[0].width == .fraction(0.25))
  }

  @Test func cycleWidthHandlesFixedAndEmptyPresets() {
    var strip = makeStrip(1)
    strip.setFixedWidth(300, of: id(1))
    let moved = strip.cycleWidth(config: config)
    #expect(moved)
    #expect(strip.columns[0].width == .fraction(0.25))
    let moved2 = strip.cycleWidth(config: LayoutConfig(presetWidths: []))
    #expect(!moved2)
    var empty = Strip()
    let emptyCycled = empty.cycleWidth(config: config)
    #expect(!emptyCycled)
  }

  @Test func toggleFullWidthKeepsStoredWidth() {
    var strip = makeStrip(1)
    let width = strip.columns[0].width
    strip.toggleFullWidth()
    #expect(strip.columns[0].isFullWidth)
    #expect(strip.columns[0].width == width)
    strip.toggleFullWidth()
    #expect(!strip.columns[0].isFullWidth)
    var empty = Strip()
    empty.toggleFullWidth()
    #expect(empty.isEmpty)
  }

  @Test(arguments: [
    (start: 0.5, delta: 0.05, expected: 0.55),
    (start: 0.5, delta: -0.05, expected: 0.45),
    (start: 0.95, delta: 0.1, expected: 1.0),
    (start: 0.15, delta: -0.1, expected: 0.1),
  ])
  func adjustWidthClamps(start: Double, delta: Double, expected: Double) {
    var strip = makeStrip(1)
    strip.columns[0].width = .fraction(start)
    let moved = strip.adjustWidth(by: delta, viewportWidth: 1016, config: config)
    #expect(moved)
    guard case .fraction(let result) = strip.columns[0].width else {
      Issue.record("width is not a fraction")
      return
    }
    #expect(abs(result - expected) < 1e-9)
  }

  @Test func adjustWidthReportsNoChangeAtBounds() {
    var strip = makeStrip(1)
    strip.columns[0].width = .fraction(0.1)
    let moved = strip.adjustWidth(by: -0.05, viewportWidth: 1016, config: config)
    #expect(!moved)
    strip.columns[0].width = .fraction(1.0)
    let moved2 = strip.adjustWidth(by: 0.05, viewportWidth: 1016, config: config)
    #expect(!moved2)
  }

  @Test func adjustWidthConvertsFixedToFraction() {
    var strip = makeStrip(1)
    strip.setFixedWidth(496, of: id(1))
    let moved = strip.adjustWidth(by: 0.1, viewportWidth: 1016, config: config)
    #expect(moved)
    guard case .fraction(let result) = strip.columns[0].width else {
      Issue.record("width is not a fraction")
      return
    }
    #expect(abs(result - 0.6) < 1e-9)
  }

  @Test func adjustWidthFromFullWidthStartsAtOne() {
    var strip = makeStrip(1)
    strip.toggleFullWidth()
    let moved = strip.adjustWidth(by: -0.25, viewportWidth: 1016, config: config)
    #expect(moved)
    #expect(!strip.columns[0].isFullWidth)
    #expect(strip.columns[0].width == .fraction(0.75))
  }

  @Test func setFixedWidthTargetsColumnOfWindow() {
    var strip = makeStrip(2)
    strip.toggleFullWidth()
    strip.setFixedWidth(321, of: id(1))
    #expect(strip.columns[0].width == .fixed(321))
    #expect(strip.columns[1].isFullWidth)
    strip.setFixedWidth(10, of: id(1))
    strip.setFixedWidth(50, of: id(99))
    #expect(strip.columns[0].width == .fixed(10))
  }

  private func stackOfThree() -> Strip {
    makeStack(3)
  }

  @Test func adjustHeightGrowsFocusedRowAndKeepsOthersProportional() {
    var strip = stackOfThree()
    strip.focus(id(2))
    strip.adjustHeight(by: 0.1)
    let weights = strip.columns[0].heightWeights
    #expect(abs(weights[1] - 3 * (1.0 / 3.0 + 0.1)) < 1e-9)
    #expect(abs(weights[0] - weights[2]) < 1e-9)
    #expect(abs(weights.reduce(0, +) - 3) < 1e-9)
  }

  @Test func adjustHeightKeepsMinimumShare() {
    var strip = stackOfThree()
    let moved = strip.adjustHeight(by: 5)
    #expect(moved)
    var weights = strip.columns[0].heightWeights
    #expect(abs(weights[2] - 3 * 0.8) < 1e-9)
    #expect(abs(weights[0] - 0.3) < 1e-9)
    let moved2 = strip.adjustHeight(by: 5)
    #expect(!moved2)
    let moved3 = strip.adjustHeight(by: -5)
    #expect(moved3)
    weights = strip.columns[0].heightWeights
    #expect(abs(weights[2] - 0.3) < 1e-9)
    #expect(abs(weights[0] - 1.35) < 1e-9)
    #expect(weights.allSatisfy { $0 >= 0.3 - 1e-9 })
    #expect(abs(weights.reduce(0, +) - 3) < 1e-9)
  }

  @Test func adjustHeightRedistributesWithoutDroppingBelowMinimum() {
    var strip = stackOfThree()
    strip.focus(id(1))
    strip.adjustHeight(by: 0.5)
    strip.focus(id(2))
    strip.adjustHeight(by: 0.3)
    let shares = strip.columns[0].heightWeights.map { $0 / 3 }
    #expect(shares.allSatisfy { $0 >= 0.1 - 1e-9 })
    #expect(abs(shares.reduce(0, +) - 1) < 1e-9)
  }

  @Test func adjustHeightRejectsSingleRowAndTabbedColumns() {
    var strip = makeStrip(2)
    let moved = strip.adjustHeight(by: 0.1)
    #expect(!moved)
    strip.stackFocused(into: .left)
    strip.toggleTabbed()
    let moved2 = strip.adjustHeight(by: 0.1)
    #expect(!moved2)
    var empty = Strip()
    let emptyAdjusted = empty.adjustHeight(by: 0.1)
    #expect(!emptyAdjusted)
  }

  @Test func equalizeHeightsResetsWeights() {
    var strip = stackOfThree()
    strip.adjustHeight(by: 0.3)
    strip.equalizeHeights()
    #expect(strip.columns[0].heightWeights == [1, 1, 1])
    var empty = Strip()
    empty.equalizeHeights()
  }
}
