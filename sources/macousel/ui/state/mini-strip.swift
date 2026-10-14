import StripCore

struct MiniStrip: Equatable {
  struct Column: Equatable {
    let x: Double
    let width: Double
    let isFocused: Bool
  }

  private static let width = 0.45
  private static let fittingWidth = 0.35
  private static let edge = 0.03

  let columns: [Column]

  init(columns: [Column]) {
    self.columns = columns
  }

  init(defaultWidth: Double) {
    self.init(columns: [
      Column(x: Self.edge, width: defaultWidth, isFocused: true),
      Column(x: Self.edge + defaultWidth, width: Self.width, isFocused: false),
    ])
  }

  init(centerMode: CenterMode) {
    switch centerMode {
    case .never:
      self.init(focusedLeft: 1 - Self.edge - Self.width, width: Self.width)
    case .always:
      self.init(focusedLeft: (1 - Self.width) / 2, width: Self.width)
    case .onOverflow:
      let left = (1 - Self.fittingWidth * 2) / 2
      self.init(columns: [
        Column(x: left, width: Self.fittingWidth, isFocused: false),
        Column(x: left + Self.fittingWidth, width: Self.fittingWidth, isFocused: true),
      ])
    }
  }

  private init(focusedLeft: Double, width: Double) {
    self.init(
      columns: (-2...1).map { step in
        Column(x: focusedLeft + Double(step) * width, width: width, isFocused: step == 0)
      })
  }
}
