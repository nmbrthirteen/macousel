import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct OverviewHitAreaTests {
  private func geometry(_ columns: [[UInt32]], tabbed: Set<Int> = []) -> OverviewGeometry {
    OverviewGeometry(
      snapshot: OverviewSnapshots.make(columns: columns, tabbed: tabbed), size: OverviewSnapshots.size)
  }

  @Test func everyColumnHasOneEdgeAlongItsRightSide() throws {
    let geometry = geometry([[1], [2, 3], [4]])
    let areas = geometry.hitAreas

    #expect(areas.edges.map(\.column) == [0, 1, 2])
    #expect(areas.edges.map(\.window) == [WindowID(1), WindowID(2), WindowID(4)])
    let stack = try #require(areas.edges.first { $0.column == 1 })
    let top = try #require(geometry.cards.first { $0.id == WindowID(2) })
    let bottom = try #require(geometry.cards.first { $0.id == WindowID(3) })
    #expect(stack.rect.minY == top.rect.minY)
    #expect(stack.rect.maxY == bottom.rect.maxY)
    #expect(abs(stack.rect.maxX - (top.rect.maxX + Metrics.Overview.columnGap / 2)) < 0.001)
    let width = Metrics.Overview.edgeHitWidth + Metrics.Overview.columnGap / 2
    #expect(abs(stack.rect.width - width) < 0.001)
  }

  @Test func edgesFindThePointsAlongTheRightSideOnly() throws {
    let geometry = geometry([[1], [2]])
    let card = try #require(geometry.cards.first)

    let onEdge = CGPoint(x: card.rect.maxX - 2, y: card.rect.midY)
    let inMiddle = CGPoint(x: card.rect.midX, y: card.rect.midY)
    let inGap = CGPoint(x: card.rect.maxX + Metrics.Overview.columnGap / 2 - 1, y: card.rect.midY)

    #expect(geometry.hitAreas.edge(at: onEdge)?.window == WindowID(1))
    #expect(geometry.hitAreas.edge(at: inGap)?.window == WindowID(1))
    #expect(geometry.hitAreas.edge(at: inMiddle) == nil)
  }

  @Test func eachPairOfStackedCardsHasADividerOnTheGapBetweenThem() throws {
    let geometry = geometry([[1, 2, 3]])
    let cards = geometry.cards

    let dividers = geometry.hitAreas.dividers

    #expect(dividers.map(\.upper) == [WindowID(1), WindowID(2)])
    #expect(dividers.map(\.lower) == [WindowID(2), WindowID(3)])
    let first = try #require(dividers.first)
    let gapMiddle = (cards[0].rect.maxY + cards[1].rect.minY) / 2
    #expect(abs(first.rect.midY - gapMiddle) < 0.001)
    #expect(abs(first.rect.height - Metrics.Overview.dividerHitHeight) < 0.001)
    #expect(first.rect.minX == cards[0].rect.minX && first.rect.width == cards[0].rect.width)
  }

  @Test func singleCardColumnsAndTabbedColumnsHaveNoDividers() {
    #expect(geometry([[1], [2]]).hitAreas.dividers.isEmpty)
    #expect(geometry([[1, 2]], tabbed: [0]).hitAreas.dividers.isEmpty)
    #expect(geometry([[1, 2]], tabbed: [0]).hitAreas.edges.count == 1)
  }

  @Test func dividerHitsTheGapAndNotTheCardBodies() throws {
    let geometry = geometry([[1, 2]])
    let upper = geometry.cards[0].rect
    let lower = geometry.cards[1].rect
    let gap = CGPoint(x: upper.midX, y: (upper.maxY + lower.minY) / 2)

    #expect(geometry.hitAreas.divider(at: gap)?.upper == WindowID(1))
    #expect(geometry.hitAreas.divider(at: CGPoint(x: upper.midX, y: upper.midY)) == nil)
  }

  @Test func theDropLayoutCarriesEveryCardWithItsColumnAndRow() {
    let layout = geometry([[1, 2], [3]]).dropLayout

    #expect(layout.placements.map(\.window) == [WindowID(1), WindowID(2), WindowID(3)])
    #expect(layout.placements.map(\.column) == [0, 0, 1])
    #expect(layout.placements.map(\.row) == [0, 1, 0])
  }

  @Test func everyColumnCarriesItsPlaceNumberAndTheLastOneIsNine() {
    #expect(geometry([[1], [2], [3]]).cards.compactMap(\.number) == [1, 2, 3])
    let many = geometry(Array(1...12).map { [UInt32($0)] })
    #expect(many.cards.compactMap(\.number) == Array(1...8) + [9])
    #expect(many.cards.last?.number == 9)
  }
}
