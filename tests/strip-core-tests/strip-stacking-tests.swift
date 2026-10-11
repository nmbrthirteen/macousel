import Testing

@testable import StripCore

struct StripStackingTests {
  private func closeTo(_ weights: [Double], _ expected: [Double]) -> Bool {
    weights.count == expected.count && zip(weights, expected).allSatisfy { abs($0 - $1) < 1e-9 }
  }

  @Test func windowMovesIntoTheTargetColumnAndTakesFocus() {
    var strip = makeStrip(3)

    let stacked = strip.stack(id(1), ontoColumnOf: id(3), atRow: 0)

    #expect(stacked)
    #expect(strip.columns.map(\.windows) == [[id(2)], [id(1), id(3)]])
    #expect(strip.focusedColumn == 1)
    #expect(strip.focusedWindow == id(1))
    #expect(invariantViolations(strip).isEmpty)
  }

  @Test func theSourceColumnDisappearsWhenTheWindowWasAlone() {
    var strip = makeStrip(3)

    strip.stack(id(3), ontoColumnOf: id(1), atRow: 1)

    #expect(strip.columns.count == 2)
    #expect(strip.columns[0].windows == [id(1), id(3)])
    #expect(strip.focusedColumn == 0)
    #expect(invariantViolations(strip).isEmpty)
  }

  @Test func theSourceColumnKeepsItsOtherWindows() {
    var strip = makeStrip(3)
    strip.focus(id(2))
    strip.stackFocused(into: .left)

    strip.stack(id(2), ontoColumnOf: id(3), atRow: 1)

    #expect(strip.columns.map(\.windows) == [[id(1)], [id(3), id(2)]])
    #expect(invariantViolations(strip).isEmpty)
  }

  @Test(arguments: [(-5, [1, 2]), (0, [1, 2]), (1, [2, 1]), (99, [2, 1])] as [(Int, [UInt32])])
  func theRowIsClamped(row: Int, expected: [UInt32]) {
    var strip = makeStrip(2)

    strip.stack(id(1), ontoColumnOf: id(2), atRow: row)

    #expect(strip.columns.count == 1)
    #expect(strip.columns[0].windows == expected.map { id($0) })
  }

  @Test func theInsertedWindowGetsTheAverageHeightWeight() {
    var strip = makeStack(2)
    strip.setHeightWeights([0.5, 1.5], ofColumnContaining: id(1))
    strip.insert(id(9), config: LayoutConfig())

    strip.stack(id(9), ontoColumnOf: id(2), atRow: 2)

    #expect(closeTo(strip.columns[0].heightWeights, [0.5, 1.5, 1.0]))
    #expect(invariantViolations(strip).isEmpty)
  }

  @Test func aWindowAlreadyInTheColumnMovesToTheRowAndKeepsItsWeight() {
    var strip = makeStack(3)
    strip.setHeightWeights([0.5, 1.0, 1.5], ofColumnContaining: id(1))

    let stacked = strip.stack(id(1), ontoColumnOf: id(3), atRow: 2)

    #expect(stacked)
    #expect(strip.columns[0].windows == [id(2), id(3), id(1)])
    #expect(closeTo(strip.columns[0].heightWeights, [1.0, 1.5, 0.5]))
    #expect(strip.focusedWindow == id(1))
    #expect(invariantViolations(strip).isEmpty)
  }

  @Test func stackingOntoItselfOrAMissingWindowChangesNothing() {
    var strip = makeStrip(2)
    let before = strip

    let onItself = strip.stack(id(1), ontoColumnOf: id(1), atRow: 0)
    let missingWindow = strip.stack(id(9), ontoColumnOf: id(1), atRow: 0)
    let missingTarget = strip.stack(id(1), ontoColumnOf: id(9), atRow: 0)

    #expect(!onItself && !missingWindow && !missingTarget)
    #expect(strip == before)
  }

  @Test func focusedColumnFollowsWhenAnEarlierColumnDisappears() {
    var strip = makeStrip(4)

    strip.stack(id(1), ontoColumnOf: id(4), atRow: 1)

    #expect(strip.columns.map(\.windows) == [[id(2)], [id(3)], [id(4), id(1)]])
    #expect(strip.focusedColumn == 2)
    #expect(invariantViolations(strip).isEmpty)
  }
}
