import StripCore

struct OverviewRowResize {
  let upperShare: Double
  let lowerShare: Double
  let columnHeight: Double

  func resolve(translation: Double) -> (upper: Double, lower: Double) {
    let pair = upperShare + lowerShare
    let floor = Column.minimumHeightShare
    guard columnHeight > 0, pair >= 2 * floor else { return (upperShare, lowerShare) }
    let upper = min(max(upperShare + translation / columnHeight, floor), pair - floor)
    return (upper, pair - upper)
  }
}
