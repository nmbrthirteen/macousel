import StripCore
import SwiftUI
import Testing

@testable import Macousel

@MainActor
struct MiniStripTests {
  private func focused(_ strip: MiniStrip) -> MiniStrip.Column? {
    strip.columns.first(where: \.isFocused)
  }

  @Test func alwaysCentersTheFocusedColumn() throws {
    let column = try #require(focused(MiniStrip(centerMode: .always)))
    #expect(abs(column.x + column.width / 2 - 0.5) < 0.001)
  }

  @Test func neverLeavesTheFocusedColumnAtTheEdge() throws {
    let column = try #require(focused(MiniStrip(centerMode: .never)))
    #expect(column.x + column.width > 0.95)
  }

  @Test func aStripThatFitsIsCenteredAsAWhole() {
    let columns = MiniStrip(centerMode: .onOverflow).columns
    let left = columns.map(\.x).min() ?? 0
    let right = columns.map { $0.x + $0.width }.max() ?? 0
    #expect(abs(left - (1 - right)) < 0.001)
  }

  @Test func theDefaultWidthSetsTheFocusedColumn() {
    #expect(focused(MiniStrip(defaultWidth: 0.75))?.width == 0.75)
  }

  @Test func aCustomWidthSelectsTheNearestTile() {
    var width = 0.52
    let binding = PercentPicker.nearest(
      in: PercentPicker.standardOptions, to: Binding(get: { width }, set: { width = $0 }))
    #expect(binding.wrappedValue == 0.5)
    binding.wrappedValue = 0.75
    #expect(width == 0.75)
  }
}
