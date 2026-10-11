import StripCore

struct OverviewColumnResize {
  struct Result: Equatable {
    var fraction: Double
    var width: Double
  }

  let startWidth: Double
  let scale: Double
  let usableWidth: Double
  let innerGap: Double
  let presetWidths: [Double]

  init(column: OverviewSnapshot.Column, scale: Double, snapshot: OverviewSnapshot) {
    startWidth = column.width
    self.scale = scale
    usableWidth = snapshot.usableWidth
    innerGap = snapshot.innerGap
    presetWidths = snapshot.presetWidths
  }

  var isResolvable: Bool { scale > 0 && usableWidth > 0 }

  func resolve(translation: Double) -> Result {
    let width = max(startWidth + translation / scale, 0)
    let raw = (width + innerGap) / (usableWidth + innerGap)
    let range = Strip.widthFractionRange
    var fraction = min(max(raw, range.lowerBound), range.upperBound)
    let anchors = presetWidths + [range.upperBound]
    if let nearest = anchors.min(by: { abs($0 - fraction) < abs($1 - fraction) }),
      abs(nearest - fraction) <= Metrics.Overview.presetSnapRange
    {
      fraction = nearest
    }
    return Result(fraction: fraction, width: fraction * (usableWidth + innerGap) - innerGap)
  }

  static func label(for fraction: Double) -> String {
    "\(Int((fraction * 100).rounded()))%"
  }
}
