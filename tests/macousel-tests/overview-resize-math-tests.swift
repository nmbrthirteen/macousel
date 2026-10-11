import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct OverviewResizeMathTests {
  private func columnResize(startWidth: Double = 488) -> OverviewColumnResize {
    var snapshot = OverviewSnapshots.make(columns: [[1]], width: startWidth)
    snapshot.presetWidths = [0.25, 0.5, 0.75]
    return OverviewColumnResize(column: snapshot.columns[0], scale: 0.5, snapshot: snapshot)
  }

  @Test func noMovementKeepsTheWidthFractionOfTheColumn() {
    let result = columnResize().resolve(translation: 0)

    #expect(abs(result.fraction - 0.5) < 0.001)
    #expect(abs(result.width - 488) < 0.001)
  }

  @Test func nearAPresetSnapsToIt() {
    let resize = columnResize()
    #expect(resize.resolve(translation: 10).fraction == 0.5)
    #expect(resize.resolve(translation: -10).fraction == 0.5)
    #expect(resize.resolve(translation: 120).fraction == 0.75)
  }

  @Test func awayFromEveryPresetKeepsTheRawFraction() {
    let result = columnResize().resolve(translation: 60)

    #expect(result.fraction > 0.5 && result.fraction < 0.75)
    #expect(result.fraction != 0.75)
    #expect(abs(result.width - (result.fraction * 992 - 8)) < 0.001)
  }

  @Test func nearTheFullWidthSnapsToOneAndNeverGoesPast() {
    let resize = columnResize()
    #expect(resize.resolve(translation: 240).fraction == 1.0)
    #expect(resize.resolve(translation: 5000).fraction == 1.0)
  }

  @Test func theFractionNeverGoesBelowTenPercent() {
    #expect(columnResize().resolve(translation: -5000).fraction == 0.1)
  }

  @Test func percentLabelsAreWholeNumbers() {
    #expect(OverviewColumnResize.label(for: 0.5) == "50%")
    #expect(OverviewColumnResize.label(for: 1.0 / 3.0) == "33%")
    #expect(OverviewColumnResize.label(for: 1.0) == "100%")
  }

  @Test func aDividerMovesHeightBetweenTheTwoRowsOnly() {
    let resize = OverviewRowResize(upperShare: 0.5, lowerShare: 0.5, columnHeight: 400)

    let result = resize.resolve(translation: 80)

    #expect(abs(result.upper - 0.7) < 1e-9)
    #expect(abs(result.lower - 0.3) < 1e-9)
  }

  @Test func theDividerStopsAtTheEnginesMinimumShare() {
    let resize = OverviewRowResize(upperShare: 0.4, lowerShare: 0.4, columnHeight: 400)

    #expect(resize.resolve(translation: 5000).upper == 0.8 - Column.minimumHeightShare)
    #expect(resize.resolve(translation: -5000).upper == Column.minimumHeightShare)
  }

  @Test func theOtherRowsOfAThreeRowColumnKeepTheirShare() {
    let resize = OverviewRowResize(upperShare: 0.2, lowerShare: 0.3, columnHeight: 500)

    let result = resize.resolve(translation: 100)

    #expect(abs(result.upper + result.lower - 0.5) < 1e-9)
  }
}
