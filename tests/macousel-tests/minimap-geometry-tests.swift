import CoreGraphics
import Testing

@testable import Macousel

@MainActor
struct MinimapGeometryTests {
  private let size = CGSize(width: 200, height: 20)

  private func snapshot(columns: Int, focused: Int = 0, stackedFirst: Bool = false)
    -> MinimapSnapshot
  {
    MinimapSnapshot(
      columns: (0..<columns).map { index in
        MinimapSnapshot.Column(
          x: Double(index) * 500, width: 492,
          rowShares: stackedFirst && index == 0 ? [1, 1] : [1], isFocused: index == focused)
      },
      contentWidth: Double(columns) * 500 - 8, viewportOffset: 0, viewportWidth: 1000)
  }

  @Test func everyRowBecomesOneCellInsideTheMap() {
    let geometry = MinimapGeometry(snapshot: snapshot(columns: 4, stackedFirst: true), size: size)
    #expect(geometry.cells.count == 5)
    #expect(Set(geometry.cells.map(\.id)).count == 5)
    #expect(geometry.cells.allSatisfy { $0.rect.minX >= 0 && $0.rect.maxX <= size.width + 0.5 })
    #expect(geometry.cells.filter(\.isFocused).count == 2)
  }

  @Test func viewportOutlineCoversTheVisibleShare() {
    let geometry = MinimapGeometry(snapshot: snapshot(columns: 4), size: size)
    #expect(abs(geometry.viewport.width - size.width * 1000 / 1992) < 0.01)
    #expect(geometry.viewport.height == size.height)
  }

  @Test func wideColumnsAreNumberedInOrderUpToNine() {
    let geometry = MinimapGeometry(snapshot: snapshot(columns: 3), size: size)
    #expect(geometry.labels.map(\.number) == [1, 2, 3])
    let crowded = MinimapGeometry(snapshot: snapshot(columns: 40), size: size)
    #expect(crowded.labels.isEmpty)
  }

  @Test func emptySnapshotProducesNothing() {
    let empty = MinimapSnapshot(columns: [], contentWidth: 0, viewportOffset: 0, viewportWidth: 0)
    let geometry = MinimapGeometry(snapshot: empty, size: size)
    #expect(geometry.cells.isEmpty && geometry.labels.isEmpty)
  }
}
