import Foundation
import Testing

@testable import StripCore

struct StripMembershipTests {
  let config = LayoutConfig()

  @Test func emptyStripHasNoFocus() {
    let strip = Strip()
    #expect(strip.isEmpty)
    #expect(strip.focusedColumn == nil)
    #expect(strip.focusedWindow == nil)
    #expect(strip.windows.isEmpty)
  }

  @Test func insertGoesRightOfFocusAndTakesFocus() {
    var strip = makeStrip(3)
    strip.focus(id(1))
    strip.insert(id(9), config: config)
    #expect(strip.windows == [id(1), id(9), id(2), id(3)])
    #expect(strip.focusedWindow == id(9))
    #expect(strip.focusedColumn == 1)
  }

  @Test func insertUsesDefaultWidth() {
    var strip = Strip()
    strip.insert(id(1), config: LayoutConfig(defaultWidth: 0.75))
    #expect(strip.columns[0].width == .fraction(0.75))
  }

  @Test func insertIsNoOpForExistingWindow() {
    var strip = makeStrip(3)
    let before = strip
    strip.insert(id(1), config: config)
    #expect(strip == before)
  }

  @Test func appendKeepsFocusUnlessEmpty() {
    var strip = Strip()
    strip.append(id(1), width: .fixed(300))
    #expect(strip.focusedWindow == id(1))
    strip.append(id(2), width: .fraction(0.5))
    #expect(strip.focusedWindow == id(1))
    #expect(strip.windows == [id(1), id(2)])
    #expect(strip.columns[0].width == .fixed(300))
  }

  @Test func appendIsNoOpForExistingWindow() {
    var strip = makeStrip(2)
    let before = strip
    strip.append(id(2), width: .fraction(0.5))
    #expect(strip == before)
  }

  @Test func removeUnknownWindowReturnsFalse() {
    var strip = makeStrip(2)
    let moved = strip.remove(id(99))
    #expect(!moved)
  }

  @Test func removingFocusedColumnFocusesWindowThatSlidIntoPlace() {
    var strip = makeStrip(4)
    strip.focus(id(2))
    let moved = strip.remove(id(2))
    #expect(moved)
    #expect(strip.focusedWindow == id(3))
    #expect(strip.focusedColumn == 1)
  }

  @Test func removingLastColumnClampsFocus() {
    var strip = makeStrip(3)
    strip.remove(id(3))
    #expect(strip.focusedWindow == id(2))
  }

  @Test func removingColumnLeftOfFocusKeepsFocusedWindow() {
    var strip = makeStrip(3)
    strip.focus(id(3))
    strip.remove(id(1))
    #expect(strip.focusedWindow == id(3))
    #expect(strip.focusedColumn == 1)
  }

  @Test func removingColumnRightOfFocusKeepsFocusedWindow() {
    var strip = makeStrip(3)
    strip.focus(id(1))
    strip.remove(id(3))
    #expect(strip.focusedWindow == id(1))
  }

  @Test func removingLastWindowEmptiesStrip() {
    var strip = makeStrip(1)
    strip.remove(id(1))
    #expect(strip.isEmpty)
    #expect(strip.focusedColumn == nil)
  }

  @Test func removeFromStackKeepsRelativeWeightsAndFallsBackToStacked() {
    var strip = makeStack(3)
    #expect(strip.columns.count == 1)
    strip.focus(id(1))
    strip.adjustHeight(by: 0.2)
    let weights = strip.columns[0].heightWeights
    strip.toggleTabbed()
    strip.remove(id(3))
    let remaining = strip.columns[0].heightWeights
    #expect(abs(remaining[0] / remaining[1] - weights[0] / weights[1]) < 1e-9)
    #expect(abs(remaining.reduce(0, +) - 2) < 1e-9)
    strip.remove(id(2))
    #expect(strip.columns[0].display == .stacked)
    #expect(strip.columns[0].heightWeights == [1.0])
  }

  @Test func removingRowAboveActiveRowKeepsActiveWindow() {
    var strip = makeStack(3)
    #expect(strip.focusedWindow == id(3))
    strip.remove(id(1))
    #expect(strip.focusedWindow == id(3))
    strip.remove(id(3))
    #expect(strip.focusedWindow == id(2))
  }

  @Test func lookups() {
    var strip = makeStrip(3)
    strip.stackFocused(into: .left)
    #expect(strip.contains(id(3)))
    #expect(!strip.contains(id(7)))
    #expect(strip.columnIndex(of: id(3)) == 1)
    #expect(strip.columnIndex(of: id(7)) == nil)
    #expect(strip.windows == [id(1), id(2), id(3)])
  }

  @Test func stripRoundTripsThroughCodable() throws {
    var strip = makeStrip(4)
    strip.stackFocused(into: .left)
    strip.adjustHeight(by: 0.1)
    strip.scrollOffset = 42
    let data = try JSONEncoder().encode(strip)
    #expect(try JSONDecoder().decode(Strip.self, from: data) == strip)
  }
}
