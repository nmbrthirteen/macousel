import Testing

@testable import StripCore

struct StripInvariantTests {
  private enum Operation: CaseIterable {
    case insert, append, remove, stackOnto, focusColumn, setFullWidth, focusWindow, focusDirection, focusFirst, focusLast
    case moveFocused, moveToColumn, cycleWidth, toggleFullWidth, adjustWidth, setFixedWidth
    case adjustHeight, equalizeHeights, stack, popOut, toggleTabbed
    case scrollToFocus, centerFocused, settle
  }

  private func apply(
    _ operation: Operation, to strip: inout Strip, nextID: inout UInt32,
    config: LayoutConfig, using rng: inout SeededGenerator
  ) {
    let known = strip.windows
    let pick = known.randomElement(using: &rng) ?? id(0)
    switch operation {
    case .insert:
      nextID += 1
      strip.insert(id(nextID), config: config)
    case .append:
      nextID += 1
      strip.append(id(nextID), width: .fraction(Double.random(in: 0.2...0.9, using: &rng)))
    case .remove: strip.remove(pick)
    case .stackOnto:
      strip.stack(pick, ontoColumnOf: known.randomElement(using: &rng) ?? id(0), atRow: Int.random(in: -1...4, using: &rng))
    case .focusColumn: strip.focusColumn(Int.random(in: -1...6, using: &rng))
    case .setFullWidth: strip.setFullWidth(Bool.random(using: &rng), of: pick)
    case .focusWindow: strip.focus(pick)
    case .focusDirection: strip.focus(Direction.allCases.randomElement(using: &rng) ?? .left)
    case .focusFirst: strip.focusFirst()
    case .focusLast: strip.focusLast()
    case .moveFocused: strip.moveFocused(Direction.allCases.randomElement(using: &rng) ?? .left)
    case .moveToColumn: strip.move(pick, toColumn: Int.random(in: -1...6, using: &rng))
    case .cycleWidth: strip.cycleWidth(config: config)
    case .toggleFullWidth: strip.toggleFullWidth()
    case .adjustWidth:
      strip.adjustWidth(
        by: [-0.3, -0.05, 0.05, 0.3].randomElement(using: &rng) ?? 0.05, viewportWidth: 1016,
        config: config)
    case .setFixedWidth: strip.setFixedWidth(Double.random(in: 50...2000, using: &rng), of: pick)
    case .adjustHeight:
      strip.adjustHeight(by: [-0.4, -0.1, 0.1, 0.4].randomElement(using: &rng) ?? 0.1)
    case .equalizeHeights: strip.equalizeHeights()
    case .stack:
      strip.stackFocused(into: HorizontalDirection.allCases.randomElement(using: &rng) ?? .left)
    case .popOut:
      strip.popOutFocused(to: HorizontalDirection.allCases.randomElement(using: &rng) ?? .left)
    case .toggleTabbed: strip.toggleTabbed()
    case .scrollToFocus: strip.scrollToFocus(viewportWidth: 1016, config: config)
    case .centerFocused: strip.centerFocused(viewportWidth: 1016, config: config)
    case .settle:
      strip.settle(
        at: Double.random(in: -500...3000, using: &rng), viewportWidth: 1016, config: config)
    }
  }

  @Test(arguments: [1, 2, 3, 42, 2024] as [UInt64])
  func invariantsHoldAfterEveryRandomOperation(seed: UInt64) {
    var rng = SeededGenerator(seed: seed)
    var strip = Strip()
    var nextID: UInt32 = 0
    for mode in CenterMode.allCases {
      let config = LayoutConfig(centerMode: mode)
      for step in 0..<150 {
        let operation = Operation.allCases.randomElement(using: &rng) ?? .insert
        apply(operation, to: &strip, nextID: &nextID, config: config, using: &rng)
        let problems = invariantViolations(strip)
        #expect(problems.isEmpty, "seed \(seed) mode \(mode) step \(step) \(operation): \(problems)")
        if !problems.isEmpty { return }

        let layout = strip.layout(in: testViewport, config: config)
        #expect(layout.placements.count == strip.windows.count)
        #expect(layout.placements.map(\.window) == strip.windows)
        #expect(layout.placements.filter(\.isFocused).count == (strip.isEmpty ? 0 : 1))
      }
    }
  }
}
