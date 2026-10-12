import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct EngineDropPreviewTests {
  private let viewport = CGRect(x: 0, y: 24, width: 4000, height: 776)
  private let columns = FakePaneruStrip(columns: [[1], [2], [3, 4]]).snapshot.tiledColumns

  private var preview: EngineDropPreview {
    EngineDropPreview(columns: columns, viewport: viewport)
  }

  private var targeting: EngineDropTargeting {
    EngineDropTargeting(columns: columns, viewport: viewport)
  }

  @Test func insertBetweenTwoColumnsCentresOnTheGap() {
    let frame = preview.frame(for: .column(position: 1), dragging: WindowID(1))

    #expect(frame == CGRect(x: 1500, y: 0, width: 960, height: 900))
  }

  @Test func insertAtTheEndSitsBesideTheLastColumn() {
    let frame = preview.frame(for: .column(position: 2), dragging: WindowID(1))

    #expect(frame == CGRect(x: 2960, y: 0, width: 960, height: 900))
  }

  @Test func insertAtTheStartSitsBesideTheFirstColumn() {
    let frame = preview.frame(for: .column(position: 0), dragging: WindowID(1))

    #expect(frame == CGRect(x: 40, y: 0, width: 960, height: 900))
  }

  @Test func theSlotStaysInsideTheViewport() {
    let narrow = EngineDropPreview(
      columns: columns, viewport: CGRect(x: 0, y: 24, width: 3000, height: 776))

    let frame = narrow.frame(for: .column(position: 2), dragging: WindowID(1))

    #expect(frame?.maxX == 3000)
  }

  @Test func stackingAboveCoversTheTopHalfOfTheTarget() {
    let frame = preview.frame(for: .stack(onto: WindowID(3), side: .above), dragging: WindowID(1))

    #expect(frame == CGRect(x: 2000, y: 0, width: 960, height: 200))
  }

  @Test func stackingBelowCoversTheBottomHalfOfTheTarget() {
    let frame = preview.frame(for: .stack(onto: WindowID(2), side: .below), dragging: WindowID(1))

    #expect(frame == CGRect(x: 1000, y: 200, width: 960, height: 200))
  }

  @Test func nowhereHasNoPreview() {
    #expect(preview.frame(for: .nowhere, dragging: WindowID(1)) == nil)
  }

  @Test func blankSpaceAfterTheLastColumnTargetsTheEnd() {
    let target = targeting.target(dragging: WindowID(1), at: CGPoint(x: 3600, y: 400))

    #expect(target == .column(position: 2))
  }

  @Test func blankSpaceBeforeTheFirstColumnTargetsTheStart() {
    let target = targeting.target(dragging: WindowID(3), at: CGPoint(x: 0, y: 400))
    let shifted = EngineDropTargeting(
      columns: columns, viewport: CGRect(x: -500, y: 24, width: 4500, height: 776))

    let beforeTheStrip = shifted.target(dragging: WindowID(2), at: CGPoint(x: -200, y: 400))

    #expect(target == .column(position: 0))
    #expect(beforeTheStrip == .column(position: 0))
  }

  @Test func columnsOffTheScreenAreNeverTargets() {
    let narrow = EngineDropTargeting(
      columns: columns, viewport: CGRect(x: 0, y: 24, width: 1900, height: 776))

    let target = narrow.target(dragging: WindowID(1), at: CGPoint(x: 1890, y: 400))

    #expect(target == .column(position: 1))
  }

  @Test func aPointerAboveTheWindowsStillTargetsTheNearestRow() {
    let target = targeting.target(dragging: WindowID(1), at: CGPoint(x: 2480, y: 2))

    #expect(target == .stack(onto: WindowID(3), side: .above))
  }

  @Test func aGapBetweenColumnsTargetsAnInsertion() {
    let target = targeting.target(dragging: WindowID(1), at: CGPoint(x: 1980, y: 100))

    #expect(target == .column(position: 1))
  }

  @Test func theTopOfAWindowTargetsAStack() {
    let target = targeting.target(dragging: WindowID(1), at: CGPoint(x: 1480, y: 100))

    #expect(target == .stack(onto: WindowID(2), side: .above))
  }

  @Test func theOwnSlotChangesNothing() {
    let target = targeting.target(dragging: WindowID(2), at: CGPoint(x: 980, y: 100))

    #expect(target == .nowhere)
  }
}
