public enum RubberBand {
  public static let standardStiffness = 0.55

  public static func resisted(
    _ offset: Double, within range: ClosedRange<Double>, dimension: Double,
    stiffness: Double = standardStiffness
  ) -> Double {
    guard dimension > 0 else { return min(max(offset, range.lowerBound), range.upperBound) }
    if offset < range.lowerBound {
      return range.lowerBound - stretch(range.lowerBound - offset, dimension, stiffness)
    }
    if offset > range.upperBound {
      return range.upperBound + stretch(offset - range.upperBound, dimension, stiffness)
    }
    return offset
  }

  private static func stretch(_ overshoot: Double, _ dimension: Double, _ stiffness: Double)
    -> Double
  {
    (1 - 1 / (overshoot * stiffness / dimension + 1)) * dimension
  }
}
