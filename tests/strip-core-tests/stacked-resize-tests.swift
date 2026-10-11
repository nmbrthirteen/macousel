import CoreGraphics
import Testing

@testable import StripCore

struct StackedResizeTests {
  let config = LayoutConfig()

  private func rowHeights(_ strip: Strip) -> [CGFloat] {
    strip.layout(in: testViewport, config: config).placements.map(\.frame.height)
  }

  private func assertRowsFillTheColumn(_ strip: Strip) {
    let frames = strip.layout(in: testViewport, config: config).placements.map(\.frame)
    let top = frames.first.map { Double($0.minY) }
    let bottom = frames.last.map { Double($0.maxY) }
    #expect(top == Double(testViewport.minY) + config.outerGap)
    #expect(bottom == Double(testViewport.maxY) - config.outerGap)
    for (upper, lower) in zip(frames, frames.dropFirst()) {
      #expect(Double(lower.minY - upper.maxY) == config.innerGap)
    }
  }

  @Test func equalStackSplitsTheColumnEvenly() {
    let strip = makeStack(2)
    #expect(rowHeights(strip) == [396, 396])
    assertRowsFillTheColumn(strip)
  }

  @Test func tallerGrowsTheFocusedRowAndShrinksTheOther() {
    var strip = makeStack(2)
    let changed1 = strip.adjustHeight(by: config.heightStep)
    #expect(changed1)
    let heights = rowHeights(strip)
    #expect(heights[1] > heights[0])
    #expect(invariantViolations(strip).isEmpty)
    assertRowsFillTheColumn(strip)
  }

  @Test func repeatedTallerStopsAtTheMinimumShareOfTheOtherRows() {
    var strip = makeStack(3)
    for _ in 0..<40 { strip.adjustHeight(by: config.heightStep) }
    let shares = strip.columns[0].heightWeights.map { $0 / 3 }
    #expect(abs(shares[0] - Column.minimumHeightShare) < 1e-9)
    #expect(abs(shares[1] - Column.minimumHeightShare) < 1e-9)
    let changed2 = strip.adjustHeight(by: config.heightStep)
    #expect(!changed2)
    assertRowsFillTheColumn(strip)
  }

  @Test func repeatedShorterStopsAtTheMinimumShare() {
    var strip = makeStack(3)
    for _ in 0..<40 { strip.adjustHeight(by: -config.heightStep) }
    #expect(abs(strip.columns[0].heightWeights[2] / 3 - Column.minimumHeightShare) < 1e-9)
    let changed3 = strip.adjustHeight(by: -config.heightStep)
    #expect(!changed3)
  }

  @Test func equalizeUndoesEveryResize() {
    var strip = makeStack(3)
    strip.adjustHeight(by: 0.3)
    strip.equalizeHeights()
    #expect(strip.columns[0].heightWeights == [1, 1, 1])
  }

  @Test func draggingTheBottomEdgeBorrowsOnlyFromTheRowBelow() {
    var strip = makeStack(3)
    let before = rowHeights(strip)
    strip.focus(id(2))
    let changed4 = strip.setHeight(
        before[1] + 100, of: id(2), borrowingFrom: .below,
        viewportHeight: testViewport.height, config: config)
    #expect(changed4)
    let after = rowHeights(strip)
    #expect(after[0] == before[0])
    #expect(abs(after[1] - (before[1] + 100)) <= 1)
    #expect(abs(after[2] - (before[2] - 100)) <= 1)
    assertRowsFillTheColumn(strip)
  }

  @Test func draggingTheTopEdgeBorrowsOnlyFromTheRowAbove() {
    var strip = makeStack(3)
    let before = rowHeights(strip)
    let changed5 = strip.setHeight(
        before[2] + 60, of: id(3), borrowingFrom: .above,
        viewportHeight: testViewport.height, config: config)
    #expect(changed5)
    let after = rowHeights(strip)
    #expect(after[0] == before[0])
    #expect(abs(after[1] - (before[1] - 60)) <= 1)
    assertRowsFillTheColumn(strip)
  }

  @Test func draggedRowCannotSqueezeItsNeighborBelowTheMinimum() {
    var strip = makeStack(2)
    strip.setHeight(
      5000, of: id(1), borrowingFrom: .below, viewportHeight: testViewport.height, config: config)
    let shares = strip.columns[0].heightWeights.map { $0 / 2 }
    #expect(abs(shares[1] - Column.minimumHeightShare) < 1e-9)
    #expect(invariantViolations(strip).isEmpty)
  }

  @Test(arguments: [(UInt32(1), VerticalNeighbor.above), (UInt32(3), VerticalNeighbor.below)])
  func outerEdgesHaveNoNeighborToBorrowFrom(window: UInt32, neighbor: VerticalNeighbor) {
    var strip = makeStack(3)
    let before = strip
    let changed6 = strip.setHeight(
        300, of: id(window), borrowingFrom: neighbor, viewportHeight: testViewport.height,
        config: config)
    #expect(!changed6)
    #expect(strip == before)
  }

  @Test func heightDragIsIgnoredInSingleAndTabbedColumns() {
    var single = makeStrip(1)
    let changed7 = single.setHeight(
        300, of: id(1), borrowingFrom: .below, viewportHeight: testViewport.height, config: config)
    #expect(!changed7)
    var tabbed = makeStack(2)
    tabbed.toggleTabbed()
    let changed8 = tabbed.setHeight(
        300, of: id(1), borrowingFrom: .below, viewportHeight: testViewport.height, config: config)
    #expect(!changed8)
  }

  @Test func resizedHeightsSurviveReorderingInsideTheStack() {
    var strip = makeStack(3)
    strip.adjustHeight(by: 0.2)
    let tallWeight = strip.columns[0].heightWeights[2]
    strip.moveFocused(.up)
    #expect(strip.columns[0].windows == [id(1), id(3), id(2)])
    #expect(strip.columns[0].heightWeights[1] == tallWeight)
  }

  @Test func removingARowKeepsTheOthersInProportion() {
    var strip = makeStack(3)
    strip.adjustHeight(by: 0.2)
    let ratio = strip.columns[0].heightWeights[0] / strip.columns[0].heightWeights[2]
    strip.remove(id(2))
    let weights = strip.columns[0].heightWeights
    #expect(abs(weights[0] / weights[1] - ratio) < 1e-9)
    #expect(invariantViolations(strip).isEmpty)
    assertRowsFillTheColumn(strip)
  }

  @Test func poppingOutLeavesAFullHeightWindowAndAValidStack() {
    var strip = makeStack(3)
    strip.adjustHeight(by: 0.2)
    let changed9 = strip.popOutFocused(to: .right)
    #expect(changed9)
    #expect(rowHeights(strip).last == 800)
    #expect(invariantViolations(strip).isEmpty)
  }

  @Test func tabbingAndUntabbingKeepsResizedHeights() {
    var strip = makeStack(2)
    strip.adjustHeight(by: 0.2)
    let weights = strip.columns[0].heightWeights
    strip.toggleTabbed()
    strip.toggleTabbed()
    #expect(strip.columns[0].heightWeights == weights)
  }

  @Test func savedWeightsRestoreAndRejectAMismatchedCount() {
    var strip = makeStack(2)
    let changed10 = strip.setHeightWeights([3, 1], ofColumnContaining: id(1))
    #expect(changed10)
    #expect(strip.columns[0].heightWeights == [1.5, 0.5])
    let changed11 = strip.setHeightWeights([1, 1, 1], ofColumnContaining: id(1))
    #expect(!changed11)
    let changed12 = strip.setHeightWeights([1, 0], ofColumnContaining: id(1))
    #expect(!changed12)
  }
}
