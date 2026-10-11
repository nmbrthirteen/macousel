import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct OverviewGeometryTests {
  private let size = CGSize(width: 1000, height: 800)

  private func card(_ window: UInt32, share: Double = 1) -> OverviewSnapshot.Card {
    OverviewSnapshot.Card(
      window: WindowID(window), title: "Window \(window)", bundleIdentifier: nil,
      heightShare: share)
  }

  private func snapshot(
    widths: [Double], stacks: [Int: [Double]] = [:], selection: UInt32? = nil
  ) -> OverviewSnapshot {
    var next: UInt32 = 1
    let columns = widths.enumerated().map { index, width in
      let shares = stacks[index] ?? [1]
      let cards = shares.map { share in
        defer { next += 1 }
        return card(next, share: share)
      }
      return OverviewSnapshot.Column(width: width, cards: cards)
    }
    return OverviewSnapshot(
      columns: columns, stripHeight: 768, selection: selection.map { WindowID($0) })
  }

  @Test func wideStripIsScaledDownToFitTheDisplayWidth() {
    let geometry = OverviewGeometry(
      snapshot: snapshot(widths: Array(repeating: 496, count: 8)), size: size)
    let bounds = geometry.cards.map(\.rect).reduce(CGRect.null) { $0.union($1) }
    #expect(geometry.scale < Metrics.Overview.maximumScale)
    #expect(bounds.minX >= 0)
    #expect(bounds.maxX <= size.width)
    #expect(geometry.cards.count == 8)
  }

  @Test func stripThatJustFitsFillsTheWidthInsideTheMargins() {
    let geometry = OverviewGeometry(
      snapshot: snapshot(widths: Array(repeating: 496, count: 5)), size: size)
    let bounds = geometry.cards.map(\.rect).reduce(CGRect.null) { $0.union($1) }
    #expect(abs(bounds.minX - Metrics.Overview.edgeMargin) < 0.001)
    #expect(abs(bounds.maxX - (size.width - Metrics.Overview.edgeMargin)) < 0.001)
  }

  @Test func narrowStripIsCenteredHorizontallyAndVertically() throws {
    let geometry = OverviewGeometry(snapshot: snapshot(widths: [300, 300]), size: size)
    let bounds = geometry.cards.map(\.rect).reduce(CGRect.null) { $0.union($1) }
    #expect(abs(bounds.midX - size.width / 2) < 0.001)
    #expect(abs(bounds.midY - size.height / 2) < 0.001)
    #expect(bounds.width < size.width - 2 * Metrics.Overview.edgeMargin)
  }

  @Test func scaleNeverExceedsHalf() throws {
    let geometry = OverviewGeometry(snapshot: snapshot(widths: [200]), size: size)
    let only = try #require(geometry.cards.first)
    #expect(geometry.scale == Metrics.Overview.maximumScale)
    #expect(only.rect.width == 100)
    #expect(only.rect.height == 384)
  }

  @Test func stackedCardsShareTheColumnHeightByTheirShares() throws {
    let geometry = OverviewGeometry(
      snapshot: snapshot(widths: [400], stacks: [0: [1, 3]]), size: size)
    let top = try #require(geometry.cards.first)
    let bottom = try #require(geometry.cards.last)
    let fullHeight = 768 * geometry.scale
    #expect(abs(bottom.rect.height / top.rect.height - 3) < 0.001)
    #expect(
      abs(top.rect.height + bottom.rect.height + Metrics.Overview.stackGap - fullHeight) < 0.001)
    #expect(abs(bottom.rect.minY - top.rect.maxY - Metrics.Overview.stackGap) < 0.001)
    #expect(top.rect.minX == bottom.rect.minX && top.rect.width == bottom.rect.width)
  }

  @Test func cardRectanglesDoNotOverlap() {
    let geometry = OverviewGeometry(
      snapshot: snapshot(
        widths: [300, 500, 400, 600, 300, 450], stacks: [1: [1, 1, 2], 4: [3, 1]]),
      size: size)
    let rects = geometry.cards.map(\.rect)
    for (index, rect) in rects.enumerated() {
      for other in rects[(index + 1)...] {
        #expect(!rect.intersects(other))
      }
    }
  }

  @Test func onlyTheFirstCardOfEachColumnCarriesTheColumnNumber() {
    let geometry = OverviewGeometry(
      snapshot: snapshot(widths: [300, 300, 300], stacks: [1: [1, 1]]), size: size)
    #expect(geometry.cards.map(\.number) == [1, 2, nil, 3])
  }

  @Test func columnsPastTheNinthAreNotNumbered() {
    let geometry = OverviewGeometry(
      snapshot: snapshot(widths: Array(repeating: 100, count: 11)), size: size)
    #expect(geometry.cards.compactMap(\.number) == Array(1...9))
  }

  @Test func theSelectedWindowIsTheOnlySelectedCard() {
    let geometry = OverviewGeometry(
      snapshot: snapshot(widths: [300, 300, 300], selection: 2), size: size)
    #expect(geometry.cards.filter(\.isSelected).map(\.id) == [WindowID(2)])
  }

  @Test func emptySnapshotAndEmptySizeProduceNothing() {
    #expect(OverviewGeometry(snapshot: .empty, size: size).cards.isEmpty)
    #expect(OverviewGeometry(snapshot: snapshot(widths: [300]), size: .zero).cards.isEmpty)
  }
}
