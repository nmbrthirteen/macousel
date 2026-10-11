import Testing

@testable import StripCore

struct StripWidthFractionTests {
  @Test func setsTheFractionOfTheColumnHoldingTheWindow() {
    var strip = makeStack(2)
    strip.insert(id(3), config: LayoutConfig())

    let changed = strip.setWidthFraction(0.75, ofColumnContaining: id(2))

    #expect(changed)
    #expect(strip.columns[0].width == .fraction(0.75))
    #expect(strip.columns[1].width == .fraction(0.5))
  }

  @Test(arguments: [(0.01, 0.1), (0.0, 0.1), (1.4, 1.0), (0.4, 0.4)])
  func clampsToTheAllowedRange(requested: Double, stored: Double) {
    var strip = makeStrip(1)

    strip.setWidthFraction(requested, ofColumnContaining: id(1))

    #expect(strip.columns[0].width == .fraction(stored))
  }

  @Test func replacesAFixedWidthAndFullWidth() {
    var strip = makeStrip(1)
    strip.setFixedWidth(300, of: id(1))
    strip.setFullWidth(true, of: id(1))

    strip.setWidthFraction(0.5, ofColumnContaining: id(1))

    #expect(strip.columns[0].width == .fraction(0.5))
    #expect(!strip.columns[0].isFullWidth)
  }

  @Test func unknownWindowChangesNothing() {
    var strip = makeStrip(2)
    let before = strip

    let changed = strip.setWidthFraction(0.3, ofColumnContaining: id(9))

    #expect(!changed)
    #expect(strip == before)
  }
}
