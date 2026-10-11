enum SliderReadout {
  case points
  case percent

  func text(for value: Double) -> String {
    switch self {
    case .points: "\(Int(value)) pt"
    case .percent: "\(value.wholePercent)%"
    }
  }
}
