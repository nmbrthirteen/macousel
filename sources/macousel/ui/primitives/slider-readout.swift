import Foundation

enum SliderReadout {
  case points
  case percent
  case multiplier

  func text(for value: Double) -> String {
    switch self {
    case .points: "\(Int(value)) pt"
    case .percent: "\(value.wholePercent)%"
    case .multiplier: "\(value.formatted(.number.precision(.fractionLength(1))))×"
    }
  }
}
