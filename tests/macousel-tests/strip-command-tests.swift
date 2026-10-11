import StripCore
import Testing

@testable import Macousel

@MainActor
struct StripCommandTests {
  let config = LayoutConfig()
  let viewportWidth = 1016.0

  private func strip(windows count: UInt32) -> Strip {
    var strip = Strip()
    for value in 0..<count {
      strip.insert(WindowID(value + 1), config: config)
    }
    return strip
  }

  private func apply(_ action: Action, to strip: inout Strip) -> StripCommandOutcome {
    strip.apply(action, viewportWidth: viewportWidth, config: config)
  }

  @Test func focusMovesBetweenColumns() {
    var strip = strip(windows: 3)
    #expect(apply(.focusLeft, to: &strip) == .applied)
    #expect(strip.focusedWindow == WindowID(2))
  }

  @Test func focusPastTheFirstColumnReportsTheLeftEdge() {
    var strip = strip(windows: 2)
    _ = apply(.focusFirst, to: &strip)
    #expect(apply(.focusLeft, to: &strip) == .blockedAtEdge(.left))
  }

  @Test func focusPastTheLastColumnReportsTheRightEdge() {
    var strip = strip(windows: 2)
    #expect(apply(.focusRight, to: &strip) == .blockedAtEdge(.right))
  }

  @Test func centerKeepsItsOwnScrollOffset() {
    var strip = strip(windows: 3)
    #expect(apply(.center, to: &strip) == .appliedKeepingScroll)
  }

  @Test func stackingThenPoppingOutRestoresTheColumnCount() {
    var strip = strip(windows: 3)
    #expect(apply(.stackLeft, to: &strip) == .applied)
    #expect(strip.columns.count == 2)
    #expect(apply(.popOutRight, to: &strip) == .applied)
    #expect(strip.columns.count == 3)
  }

  @Test func tabbingASingleWindowColumnIsIgnored() {
    var strip = strip(windows: 1)
    #expect(apply(.toggleTabbed, to: &strip) == .ignored)
  }

  @Test(arguments: [Action.togglePaused, .toggleFloating, .sendToNextDisplay])
  func managerLevelActionsLeaveTheStripAlone(action: Action) {
    var strip = strip(windows: 2)
    let before = strip
    #expect(apply(action, to: &strip) == .ignored)
    #expect(strip == before)
  }

  @Test(arguments: Action.allCases)
  func everyActionIsSafeOnAnEmptyStrip(action: Action) {
    var strip = Strip()
    #expect(apply(action, to: &strip) != .applied)
    #expect(strip.isEmpty)
  }
}
