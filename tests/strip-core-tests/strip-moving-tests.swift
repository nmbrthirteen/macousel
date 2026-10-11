import Testing

@testable import StripCore

struct StripMovingTests {
  @Test func moveFocusedHorizontallySwapsColumnsAndKeepsFocus() {
    var strip = makeStrip(3)
    strip.focus(id(2))
    let moved = strip.moveFocused(.left)
    #expect(moved)
    #expect(strip.windows == [id(2), id(1), id(3)])
    #expect(strip.focusedWindow == id(2))
    let moved2 = strip.moveFocused(.right)
    #expect(moved2)
    let moved3 = strip.moveFocused(.right)
    #expect(moved3)
    let moved4 = strip.moveFocused(.right)
    #expect(!moved4)
    #expect(strip.windows == [id(1), id(3), id(2)])
  }

  @Test func moveFocusedHorizontallyCarriesWholeStack() {
    var strip = makeStrip(3)
    strip.focus(id(2))
    strip.stackFocused(into: .left)
    strip.moveFocused(.right)
    #expect(strip.windows == [id(3), id(1), id(2)])
    #expect(strip.columns[1].windows == [id(1), id(2)])
  }

  @Test func moveFocusedVerticallySwapsRowsAndWeights() {
    var strip = makeStrip(2)
    strip.stackFocused(into: .left)
    strip.adjustHeight(by: 0.2)
    let before = strip.columns[0].heightWeights
    let moved = strip.moveFocused(.up)
    #expect(moved)
    #expect(strip.columns[0].windows == [id(2), id(1)])
    #expect(strip.columns[0].heightWeights == before.reversed())
    #expect(strip.focusedWindow == id(2))
    let moved2 = strip.moveFocused(.up)
    #expect(!moved2)
  }

  @Test func moveFocusedVerticallyInSingleColumnFails() {
    var strip = makeStrip(2)
    let moved = strip.moveFocused(.up)
    #expect(!moved)
    let moved2 = strip.moveFocused(.down)
    #expect(!moved2)
  }

  @Test(arguments: [
    (target: 0, expected: [3, 1, 2]),
    (target: 1, expected: [1, 3, 2]),
    (target: 2, expected: [1, 2, 3]),
    (target: -5, expected: [3, 1, 2]),
    (target: 99, expected: [1, 2, 3]),
  ])
  func moveToColumnClampsIndexAfterRemoval(target: Int, expected: [UInt32]) {
    var strip = makeStrip(3)
    let moved = strip.move(id(3), toColumn: target)
    #expect(moved)
    #expect(strip.windows == expected.map(id))
    #expect(strip.focusedWindow == id(3))
    #expect(invariantViolations(strip).isEmpty)
  }

  @Test func moveUnknownWindowFails() {
    var strip = makeStrip(2)
    let moved = strip.move(id(9), toColumn: 0)
    #expect(!moved)
  }

  @Test func moveOutOfStackCreatesOwnColumnWithSourceWidth() {
    var strip = makeStrip(2)
    strip.stackFocused(into: .left)
    strip.columns[0].width = .fraction(0.75)
    let moved = strip.move(id(2), toColumn: 1)
    #expect(moved)
    #expect(strip.columns.count == 2)
    #expect(strip.columns[1].windows == [id(2)])
    #expect(strip.columns[1].width == .fraction(0.75))
    #expect(strip.columns[0].heightWeights == [1.0])
  }

  @Test func stackFocusedJoinsBottomOfNeighbourAndStaysFocused() {
    var strip = makeStrip(3)
    strip.focus(id(2))
    let moved = strip.stackFocused(into: .right)
    #expect(moved)
    #expect(strip.columns.count == 2)
    #expect(strip.columns[1].windows == [id(3), id(2)])
    #expect(strip.focusedWindow == id(2))
    #expect(strip.focusedColumn == 1)
    #expect(strip.columns[1].heightWeights == [1.0, 1.0])
  }

  @Test func stackFocusedFromMultiWindowColumnLeavesRemainder() {
    var strip = makeStack(3)
    strip.insert(id(4), config: LayoutConfig())
    let moved = strip.stackFocused(into: .left)
    #expect(moved)
    #expect(strip.columns.count == 1)
    #expect(strip.windows == [id(1), id(2), id(3), id(4)])
    strip.focus(id(2))
    let moved2 = strip.stackFocused(into: .right)
    #expect(!moved2)
  }

  @Test func stackFocusedLeftOfFirstColumnFails() {
    var strip = makeStrip(2)
    strip.focus(id(1))
    let moved = strip.stackFocused(into: .left)
    #expect(!moved)
    strip.focus(id(2))
    let moved2 = strip.stackFocused(into: .right)
    #expect(!moved2)
  }

  @Test(arguments: [HorizontalDirection.left, .right])
  func popOutCreatesColumnOnThatSide(direction: HorizontalDirection) {
    var strip = makeStrip(2)
    strip.stackFocused(into: .left)
    let moved = strip.popOutFocused(to: direction)
    #expect(moved)
    #expect(strip.columns.count == 2)
    let poppedIndex = direction == .left ? 0 : 1
    #expect(strip.columns[poppedIndex].windows == [id(2)])
    #expect(strip.focusedColumn == poppedIndex)
    #expect(strip.focusedWindow == id(2))
    #expect(strip.columns[1 - poppedIndex].display == .stacked)
  }

  @Test func popOutFailsForSingleWindowColumn() {
    var strip = makeStrip(2)
    let moved = strip.popOutFocused(to: .left)
    #expect(!moved)
    var empty = Strip()
    let emptyPopped = empty.popOutFocused(to: .right)
    #expect(!emptyPopped)
  }

  @Test func toggleTabbedFlipsAndRejectsSingleWindow() {
    var strip = makeStrip(2)
    let moved = strip.toggleTabbed()
    #expect(!moved)
    strip.stackFocused(into: .left)
    let moved2 = strip.toggleTabbed()
    #expect(moved2)
    #expect(strip.columns[0].display == .tabbed)
    let moved3 = strip.toggleTabbed()
    #expect(moved3)
    #expect(strip.columns[0].display == .stacked)
  }

  @Test func poppingOutOfTabbedPairReturnsRemainderToStacked() {
    var strip = makeStrip(2)
    strip.stackFocused(into: .left)
    strip.toggleTabbed()
    strip.popOutFocused(to: .right)
    #expect(strip.columns.allSatisfy { $0.display == .stacked })
  }
}
