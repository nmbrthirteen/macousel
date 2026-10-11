import Testing

@testable import StripCore

struct StripFocusTests {
  @Test func focusWindowByID() {
    var strip = makeStrip(3)
    let moved = strip.focus(id(1))
    #expect(moved)
    #expect(strip.focusedWindow == id(1))
    let moved2 = strip.focus(id(1))
    #expect(!moved2)
    let moved3 = strip.focus(id(99))
    #expect(!moved3)
  }

  @Test func focusWindowInsideStackSelectsRow() {
    var strip = makeStrip(2)
    strip.stackFocused(into: .left)
    let moved = strip.focus(id(1))
    #expect(moved)
    #expect(strip.columns[0].activeRow == 0)
    #expect(strip.focusedWindow == id(1))
  }

  struct Step: CustomTestStringConvertible {
    var start: UInt32
    var direction: Direction
    var expected: UInt32
    var moved: Bool
    var testDescription: String { "from \(start) \(direction) -> \(expected)" }
  }

  @Test(arguments: [
    Step(start: 2, direction: .left, expected: 1, moved: true),
    Step(start: 2, direction: .right, expected: 3, moved: true),
    Step(start: 1, direction: .left, expected: 1, moved: false),
    Step(start: 3, direction: .right, expected: 3, moved: false),
    Step(start: 2, direction: .up, expected: 2, moved: false),
    Step(start: 2, direction: .down, expected: 2, moved: false),
  ])
  func horizontalFocusDoesNotWrap(step: Step) {
    var strip = makeStrip(3)
    strip.focus(id(step.start))
    let moved = strip.focus(step.direction)
    #expect(moved == step.moved)
    #expect(strip.focusedWindow == id(step.expected))
  }

  @Test func verticalFocusMovesBetweenRowsAndStopsAtEnds() {
    var strip = makeStack(3)
    #expect(strip.focusedWindow == id(3))
    let moved = strip.focus(.down)
    #expect(!moved)
    let moved2 = strip.focus(.up)
    #expect(moved2)
    #expect(strip.focusedWindow == id(2))
    let moved3 = strip.focus(.up)
    #expect(moved3)
    let moved4 = strip.focus(.up)
    #expect(!moved4)
    #expect(strip.focusedWindow == id(1))
  }

  @Test func verticalFocusSwitchesTabs() {
    var strip = makeStrip(2)
    strip.stackFocused(into: .left)
    strip.toggleTabbed()
    let moved = strip.focus(.up)
    #expect(moved)
    #expect(strip.focusedWindow == id(1))
    let moved2 = strip.focus(.down)
    #expect(moved2)
    #expect(strip.focusedWindow == id(2))
  }

  @Test func firstAndLast() {
    var strip = makeStrip(3)
    let moved = strip.focusLast()
    #expect(!moved)
    let moved2 = strip.focusFirst()
    #expect(moved2)
    #expect(strip.focusedWindow == id(1))
    let moved3 = strip.focusFirst()
    #expect(!moved3)
    let moved4 = strip.focusLast()
    #expect(moved4)
    #expect(strip.focusedWindow == id(3))
  }

  @Test func emptyStripRejectsFocusOperations() {
    var strip = Strip()
    let moved = strip.focusFirst()
    #expect(!moved)
    let moved2 = strip.focusLast()
    #expect(!moved2)
    let moved3 = strip.focus(.left)
    #expect(!moved3)
    let moved4 = strip.focus(id(1))
    #expect(!moved4)
  }
}
