import CoreGraphics
import Testing

@testable import Macousel

@MainActor
struct MenuBarPagesGeometryTests {
  private func geometry(
    shares: [Double], focused: Int, rows: [Int: Int] = [:]
  ) -> MenuBarPagesGeometry? {
    MenuBarPagesGeometry(
      position: StripPosition(
        pages: shares.enumerated().map {
          StripPosition.Page(widthShare: $0.element, rowCount: rows[$0.offset] ?? 1)
        }, focusedIndex: focused))
  }

  @Test func everyPageIsThirteenPointsTall() throws {
    let result = try #require(geometry(shares: [0.3, 0.5, 0.4], focused: 1))
    #expect(result.pages.allSatisfy { $0.rect.height == 13 })
    #expect(result.size.height == 13)
  }

  @Test(arguments: [(0.05, 7.0), (0.25, 9.0), (0.4, 14.5), (0.5, 18.0), (1.0, 18.0)])
  func pageWidthFollowsTheColumnWidthWithinTheClamp(share: Double, width: Double) throws {
    let result = try #require(geometry(shares: [share], focused: 0))
    #expect(Double(result.pages[0].rect.width) == width)
  }

  @Test func pagesAreSeparatedByTwoPoints() throws {
    let result = try #require(geometry(shares: [0.3, 0.5, 0.4], focused: 0))
    for (left, right) in zip(result.pages, result.pages.dropFirst()) {
      #expect(right.rect.minX - left.rect.maxX == 2)
    }
    #expect(result.size.width == result.pages.last?.rect.maxX)
  }

  @Test func widerColumnsGetWiderPages() throws {
    let result = try #require(geometry(shares: [0.2, 0.3, 0.45], focused: 0))
    let widths = result.pages.map(\.rect.width)
    #expect(widths == widths.sorted())
    #expect(Set(widths).count == 3)
  }

  @Test func onlyTheFocusedPageIsActiveAndCarriesItsNumber() throws {
    let result = try #require(geometry(shares: [0.3, 0.3, 0.3, 0.3], focused: 2))
    #expect(result.pages.map(\.isActive) == [false, false, true, false])
    #expect(result.pages.map(\.number) == [nil, nil, 3, nil])
  }

  @Test func theNumberIsDroppedPastNine() throws {
    let result = try #require(geometry(shares: Array(repeating: 0.3, count: 12), focused: 9))
    let active = try #require(result.pages.first { $0.isActive })
    #expect(active.number == nil)
    let ninth = try #require(geometry(shares: Array(repeating: 0.3, count: 12), focused: 8))
    #expect(ninth.pages.first { $0.isActive }?.number == 9)
  }

  @Test func aStackedColumnSplitsIntoRowsOneApart() throws {
    let result = try #require(geometry(shares: [0.3, 0.3], focused: 0, rows: [1: 3]))
    let rows = result.pages[1].rows
    #expect(rows.count == 3)
    for (upper, lower) in zip(rows, rows.dropFirst()) {
      #expect(abs(lower.minY - upper.maxY - 1) < 0.001)
    }
    #expect(rows.first?.minY == 0)
    #expect(abs((rows.last?.maxY ?? 0) - 13) < 0.001)
    #expect(result.pages[0].rows.count == 1)
  }

  @Test(arguments: [(13.0, 2.5), (4.0, 1.0), (2.5, 0.625), (0.0, 0.0), (40.0, 2.5)])
  func aRowCornerRadiusIsCappedAtAQuarterOfItsHeight(height: Double, radius: Double) {
    #expect(MenuBarPagesGeometry.cornerRadius(forRowHeight: height) == radius)
  }

  @Test func everyRowOfAStackedColumnHasAtMostAQuarterHeightRadius() throws {
    let result = try #require(geometry(shares: [0.3], focused: 0, rows: [0: 4]))
    for row in result.pages[0].rows {
      let radius = MenuBarPagesGeometry.cornerRadius(forRowHeight: Double(row.height))
      #expect(radius <= Double(row.height) / 4)
    }
  }

  @Test func rowsAreCappedAtFour() throws {
    let result = try #require(geometry(shares: [0.3], focused: 0, rows: [0: 9]))
    #expect(result.pages[0].rows.count == 4)
  }

  @Test func aShortStripShowsEveryPageUnfaded() throws {
    let result = try #require(geometry(shares: Array(repeating: 0.3, count: 7), focused: 2))
    #expect(result.pages.count == 7)
    #expect(result.pages.allSatisfy { $0.opacity == 1 })
    #expect(result.size.width <= 120)
  }

  @Test func aLongStripShowsAWindowAroundTheActivePage() throws {
    let result = try #require(geometry(shares: Array(repeating: 0.3, count: 14), focused: 6))
    #expect(result.size.width <= 120)
    #expect(result.pages.count < 14)
    #expect(result.pages.contains { $0.isActive })
    let activeIndex = try #require(result.pages.firstIndex { $0.isActive })
    #expect(abs(activeIndex - (result.pages.count - 1 - activeIndex)) <= 1)
  }

  @Test func bothCutOffEdgesFadeInTheMiddleOfALongStrip() throws {
    let result = try #require(geometry(shares: Array(repeating: 0.3, count: 14), focused: 6))
    #expect(result.pages.first?.opacity == MenuBarPagesGeometry.cutOffOpacity)
    #expect(result.pages.last?.opacity == MenuBarPagesGeometry.cutOffOpacity)
    #expect(result.pages.dropFirst().dropLast().allSatisfy { $0.opacity == 1 })
  }

  @Test func onlyTheCutOffSideFadesAtTheStartOfALongStrip() throws {
    let result = try #require(geometry(shares: Array(repeating: 0.3, count: 14), focused: 0))
    #expect(result.pages.first?.opacity == 1)
    #expect(result.pages.last?.opacity == MenuBarPagesGeometry.cutOffOpacity)
    #expect(result.pages.first?.isActive == true)
  }

  @Test func onlyTheCutOffSideFadesAtTheEndOfALongStrip() throws {
    let result = try #require(geometry(shares: Array(repeating: 0.3, count: 14), focused: 13))
    #expect(result.pages.first?.opacity == MenuBarPagesGeometry.cutOffOpacity)
    #expect(result.pages.last?.opacity == 1)
    #expect(result.pages.last?.number == nil)
  }

  @Test(arguments: [-1, 3])
  func aFocusedIndexOutsideThePagesHasNoGeometry(focused: Int) {
    #expect(geometry(shares: [0.3, 0.3, 0.3], focused: focused) == nil)
  }

  @Test func anEmptyStripHasNoGeometry() {
    #expect(geometry(shares: [], focused: 0) == nil)
  }

  @Test func theImageIsATemplateOfTheGeometrySize() throws {
    let result = try #require(geometry(shares: [0.3, 0.5, 0.4], focused: 1))
    let image = MenuBarPagesImage.make(result)
    #expect(image.isTemplate)
    #expect(image.size == result.size)
  }
}
