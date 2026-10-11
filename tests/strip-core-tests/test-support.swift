import CoreGraphics
import Testing

@testable import StripCore

func id(_ value: UInt32) -> WindowID { WindowID(value) }

func makeStrip(_ count: UInt32, config: LayoutConfig = LayoutConfig()) -> Strip {
  var strip = Strip()
  for value in 1...max(count, 1) where value <= count {
    strip.insert(id(value), config: config)
  }
  return strip
}

let testViewport = CGRect(x: 0, y: 0, width: 1016, height: 816)

func widths(_ layout: StripLayout) -> [CGFloat] { layout.placements.map(\.frame.width) }

func invariantViolations(_ strip: Strip) -> [String] {
  var problems: [String] = []
  var seen = Set<WindowID>()
  for (index, column) in strip.columns.enumerated() {
    if column.windows.isEmpty { problems.append("column \(index) is empty") }
    if column.heightWeights.count != column.windows.count {
      problems.append("column \(index) weight count mismatch")
    }
    let sum = column.heightWeights.reduce(0, +)
    if abs(sum - Double(column.windows.count)) > 1e-6 {
      problems.append("column \(index) weights sum to \(sum)")
    }
    if column.heightWeights.contains(where: { $0 <= 0 }) {
      problems.append("column \(index) has a non-positive weight")
    }
    if !column.windows.indices.contains(column.activeRow) {
      problems.append("column \(index) activeRow out of range")
    }
    if column.windows.count == 1 && column.display == .tabbed {
      problems.append("column \(index) is a tabbed single window")
    }
    for window in column.windows where !seen.insert(window).inserted {
      problems.append("window \(window.rawValue) appears twice")
    }
  }
  switch strip.focusedColumn {
  case nil:
    if !strip.isEmpty { problems.append("non-empty strip has no focus") }
  case let focused?:
    if !strip.columns.indices.contains(focused) { problems.append("focusedColumn out of range") }
  }
  return problems
}

struct SeededGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) { state = seed }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}

func makeStack(_ count: UInt32) -> Strip {
  var strip = makeStrip(count)
  for value in 2...max(count, 2) where value <= count {
    strip.focus(id(value))
    strip.stackFocused(into: .left)
  }
  return strip
}
