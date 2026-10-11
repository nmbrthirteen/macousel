public struct WindowID: Hashable, Sendable, Codable {
  public var rawValue: UInt32

  public init(_ rawValue: UInt32) {
    self.rawValue = rawValue
  }
}

public enum Direction: Sendable, CaseIterable {
  case left, right, up, down
}

public enum HorizontalDirection: Sendable, CaseIterable {
  case left, right
}

public enum ColumnWidth: Hashable, Sendable, Codable {
  case fraction(Double)
  case fixed(Double)
}

public enum ColumnDisplay: Sendable, Codable {
  case stacked, tabbed
}

public enum CenterMode: String, Sendable, Codable, CaseIterable {
  case never, onOverflow, always
}

public struct LayoutConfig: Sendable, Codable, Equatable {
  public var innerGap: Double
  public var outerGap: Double
  public var presetWidths: [Double]
  public var defaultWidth: Double
  public var centerMode: CenterMode
  public var widthStep: Double
  public var heightStep: Double
  public var tabBarHeight: Double

  public init(
    innerGap: Double = 8,
    outerGap: Double = 8,
    presetWidths: [Double] = [0.25, 1.0 / 3.0, 0.5, 2.0 / 3.0, 0.75],
    defaultWidth: Double = 0.5,
    centerMode: CenterMode = .never,
    widthStep: Double = 0.05,
    heightStep: Double = 0.1,
    tabBarHeight: Double = 28
  ) {
    self.innerGap = innerGap
    self.outerGap = outerGap
    self.presetWidths = presetWidths
    self.defaultWidth = defaultWidth
    self.centerMode = centerMode
    self.widthStep = widthStep
    self.heightStep = heightStep
    self.tabBarHeight = tabBarHeight
  }
}
