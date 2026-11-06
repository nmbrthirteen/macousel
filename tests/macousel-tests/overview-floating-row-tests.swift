import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct OverviewFloatingRowTests {
  private let size = CGSize(width: 1000, height: 800)

  private func floater(_ window: UInt32, frame: CGRect? = nil) -> OverviewSnapshot.Card {
    OverviewSnapshot.Card(
      window: WindowID(window), title: "Floater \(window)", bundleIdentifier: nil,
      heightShare: 1, frame: frame)
  }

  private func snapshot(floating: [OverviewSnapshot.Card]) -> OverviewSnapshot {
    let columns = (1...3).map { window in
      OverviewSnapshot.Column(
        width: 480,
        cards: [
          OverviewSnapshot.Card(
            window: WindowID(UInt32(window)), title: "Window \(window)", bundleIdentifier: nil,
            heightShare: 1)
        ])
    }
    return OverviewSnapshot(
      columns: columns, stripHeight: 768, selection: nil, floating: floating)
  }

  @Test func withoutFloatingWindowsTheStripLooksTheSameAsBefore() {
    let geometry = OverviewGeometry(snapshot: snapshot(floating: []), size: size)
    let bounds = geometry.cards.map(\.rect).reduce(CGRect.null) { $0.union($1) }

    #expect(geometry.floatingCards.isEmpty)
    #expect(geometry.floatingTitleOrigin == nil)
    #expect(abs(bounds.midY - size.height / 2) < 0.001)
  }

  @Test func floatingWindowsSitInARowAboveTheStrip() throws {
    let geometry = OverviewGeometry(
      snapshot: snapshot(floating: [floater(10), floater(11)]), size: size)
    let strip = geometry.cards.map(\.rect).reduce(CGRect.null) { $0.union($1) }
    let row = geometry.floatingCards.map(\.rect).reduce(CGRect.null) { $0.union($1) }
    let title = try #require(geometry.floatingTitleOrigin)

    #expect(geometry.floatingCards.map(\.id) == [WindowID(10), WindowID(11)])
    #expect(row.maxY + Metrics.Overview.floatingRowGap <= strip.minY + 0.001)
    #expect(title.y + Metrics.Overview.floatingTitleHeight <= row.minY + 0.001)
    #expect(title.y >= Metrics.Overview.verticalMargin - 0.001)
    #expect(strip.maxY <= size.height - Metrics.Overview.verticalMargin + 0.001)
    #expect(title.x == row.minX)
  }

  @Test func floatingCardsKeepTheirWindowsShapeWithinTheRowHeight() throws {
    let tall = CGRect(x: 0, y: 0, width: 400, height: 1200)
    let geometry = OverviewGeometry(
      snapshot: snapshot(floating: [floater(10, frame: tall)]), size: size)
    let card = try #require(geometry.floatingCards.first)

    #expect(abs(card.rect.height - Metrics.Overview.floatingRowHeight) < 0.001)
    #expect(abs(card.rect.width / card.rect.height - 1.0 / 3.0) < 0.001)
  }

  @Test func aSmallFloatingWindowShowsAtTheStripScale() throws {
    let small = CGRect(x: 0, y: 0, width: 200, height: 100)
    let geometry = OverviewGeometry(
      snapshot: snapshot(floating: [floater(10, frame: small)]), size: size)
    let card = try #require(geometry.floatingCards.first)

    #expect(abs(card.rect.width - 200 * geometry.scale) < 0.001)
  }

  @Test func manyFloatingWindowsShrinkToFitTheWidth() {
    let floating = (10...30).map { floater(UInt32($0)) }
    let geometry = OverviewGeometry(snapshot: snapshot(floating: floating), size: size)
    let row = geometry.floatingCards.map(\.rect).reduce(CGRect.null) { $0.union($1) }

    #expect(row.minX >= Metrics.Overview.edgeMargin - 0.001)
    #expect(row.maxX <= size.width - Metrics.Overview.edgeMargin + 0.001)
  }

  @Test func floatingWindowsAreNotPartOfTheStripLayout() {
    let geometry = OverviewGeometry(snapshot: snapshot(floating: [floater(10)]), size: size)

    #expect(!geometry.dropLayout.placements.contains { $0.window == WindowID(10) })
    #expect(geometry.floatingCards.allSatisfy { $0.number == nil })
  }

  @Test func clickingAFloatingCardSelectsItAndDraggingItMovesNothing() throws {
    let snapshot = snapshot(floating: [floater(10)])
    let model = OverviewModel(previews: OverviewPreviews(capture: FakeWindowCapture()))
    var selected: [WindowID] = []
    var moved: [WindowID] = []
    model.onSelect = { selected.append($0) }
    model.onMove = { window, _ in moved.append(window) }
    model.show(snapshot)
    let point = try #require(
      OverviewGeometry(snapshot: snapshot, size: size).floatingCards.first
    ).rect.center

    model.pressed(at: point, in: size)
    model.released(at: point, in: size)
    model.pressed(at: point, in: size)
    model.dragged(to: CGPoint(x: point.x + 200, y: point.y + 300), in: size)
    model.released(at: CGPoint(x: point.x + 200, y: point.y + 300), in: size)

    #expect(selected == [WindowID(10)])
    #expect(moved.isEmpty)
  }
}
