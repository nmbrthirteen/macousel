import CoreGraphics
import Testing

@testable import StripCore

struct DropRulePropertyTests {
  private func randomStrip(using generator: inout SeededGenerator) -> Strip {
    let count = UInt32.random(in: 1...7, using: &generator)
    var strip = makeStrip(count)
    for _ in 0..<Int.random(in: 0...6, using: &generator) {
      let window = id(UInt32.random(in: 1...count, using: &generator))
      strip.focus(window)
      switch Int.random(in: 0..<3, using: &generator) {
      case 0: strip.stackFocused(into: .left)
      case 1: strip.stackFocused(into: .right)
      default: strip.popOutFocused(to: .right)
      }
    }
    strip.scrollToFocus(viewportWidth: testViewport.width, config: LayoutConfig())
    return strip
  }

  @Test func anyReturnedTargetKeepsTheInvariantsAndTheWindows() {
    var generator = SeededGenerator(seed: 7)
    for _ in 0..<150 {
      let strip = randomStrip(using: &generator)
      let layout = strip.layout(in: testViewport, config: LayoutConfig())
      for dragged in strip.windows {
        let rule = DropRule(strip: strip, layout: layout, viewport: testViewport, dragging: dragged)
        for _ in 0..<12 {
          let point = CGPoint(
            x: Double.random(in: -50...1066, using: &generator),
            y: Double.random(in: -50...866, using: &generator))
          let target = rule.target(at: point)
          let result = rule.applying(target)
          #expect(invariantViolations(result).isEmpty)
          #expect(Set(result.windows) == Set(strip.windows))
          #expect(result.windows.count == strip.windows.count)
          if target != .nowhere {
            #expect(result.columns.map(\.windows) != strip.columns.map(\.windows))
          }
        }
      }
    }
  }

  @Test func theSameInputsGiveTheSameTarget() {
    var generator = SeededGenerator(seed: 11)
    let strip = randomStrip(using: &generator)
    let layout = strip.layout(in: testViewport, config: LayoutConfig())
    let dragged = strip.windows[0]
    let rule = DropRule(strip: strip, layout: layout, viewport: testViewport, dragging: dragged)
    let point = CGPoint(x: 300, y: 300)
    #expect(rule.target(at: point) == rule.target(at: point))
  }
}
