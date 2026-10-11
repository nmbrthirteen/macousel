import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct MinimapHitTestTests {
  private let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 4))

  private func stacked() -> MinimapGeometry {
    let column = MinimapSnapshot.Column(
      x: 0, width: 492,
      rows: [MinimapSnapshots.row(1, height: 350), MinimapSnapshots.row(2, height: 350)],
      activeRow: 0, isTabbed: false, isFocused: true)
    return MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 3, replacing: [0: column]))
  }

  @Test func theCellUnderAPointIsFound() throws {
    for cell in geometry.cells {
      let found = try #require(geometry.cell(at: CGPoint(x: cell.rect.midX, y: cell.rect.midY)))
      #expect(found.id == cell.id)
    }
  }

  @Test func pointsOutsideEveryCellFindNothing() {
    #expect(geometry.cell(at: CGPoint(x: 1, y: 1)) == nil)
    #expect(geometry.cell(at: CGPoint(x: geometry.containerWidth + 20, y: 20)) == nil)
    #expect(geometry.cell(at: CGPoint(x: 60, y: Metrics.Minimap.height + 5)) == nil)
  }

  @Test func theUpperAndLowerHalvesOfACellAreTold() throws {
    let cell = try #require(geometry.cells.first)
    #expect(cell.isUpperHalf(at: CGPoint(x: cell.rect.midX, y: cell.rect.minY + 1)))
    #expect(!cell.isUpperHalf(at: CGPoint(x: cell.rect.midX, y: cell.rect.maxY - 1)))
  }

  @Test func stackedRowsAreHitSeparately() throws {
    let geometry = stacked()
    let upper = try #require(geometry.cells.first { $0.window == WindowID(1) })
    let lower = try #require(geometry.cells.first { $0.window == WindowID(2) })
    #expect(geometry.cell(at: CGPoint(x: upper.rect.midX, y: upper.rect.midY))?.window == WindowID(1))
    #expect(geometry.cell(at: CGPoint(x: lower.rect.midX, y: lower.rect.midY))?.window == WindowID(2))
    #expect(upper.column == 0 && upper.row == 0 && lower.row == 1)
  }

  @Test func aTabbedColumnHitsItsActiveWindow() throws {
    let column = MinimapSnapshot.Column(
      x: 0, width: 492, rows: (11...13).map { MinimapSnapshots.row($0) }, activeRow: 2,
      isTabbed: true, isFocused: true)
    let geometry = MinimapGeometry(snapshot: MinimapSnapshots.strip(columns: 2, replacing: [0: column]))
    let cell = try #require(geometry.cells.first)
    let hit = try #require(geometry.cell(at: CGPoint(x: cell.rect.midX, y: cell.rect.midY)))
    #expect(hit.window == WindowID(13))
    #expect(hit.id == WindowID(11))
    #expect(hit.row == 2)
  }

  @Test func theBoundsCoverTheWholeContainer() {
    #expect(geometry.bounds == CGRect(x: 0, y: 0, width: geometry.containerWidth, height: 40))
  }
}
