import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct MinimapShortcutHoldTests {
  private let linger = OverlayTiming.minimapLinger

  private final class Keyboard {
    var isHeld = true
  }

  private func fixture(_ keyboard: Keyboard) -> MinimapModelFixture {
    let fixture = MinimapModelFixture(snapshot: MinimapSnapshots.strip(columns: 4))
    fixture.model.isHoldingShortcut = { keyboard.isHeld }
    return fixture
  }

  @Test func holdingTheBaseModifiersKeepsTheMinimapUp() {
    let keyboard = Keyboard()
    let fixture = fixture(keyboard)
    fixture.clock.advance(by: .seconds(10))
    #expect(fixture.model.isShown)
    #expect(fixture.clock.pendingScheduleCount == 1)
  }

  @Test func releasingStartsTheLinger() {
    let keyboard = Keyboard()
    let fixture = fixture(keyboard)
    fixture.clock.advance(by: .milliseconds(1300))
    keyboard.isHeld = false
    fixture.model.shortcutReleased()
    fixture.clock.advance(by: linger - .milliseconds(1))
    #expect(fixture.model.isShown)
    fixture.clock.advance(by: .milliseconds(1))
    #expect(!fixture.model.isShown)
    #expect(fixture.visibility == [false])
  }

  @Test func aMissedReleaseStillHidesOnTheNextCheck() {
    let keyboard = Keyboard()
    let fixture = fixture(keyboard)
    fixture.clock.advance(by: linger)
    keyboard.isHeld = false
    fixture.clock.advance(by: linger)
    #expect(!fixture.model.isShown)
  }

  @Test func aReleaseWhileHoveringLeavesItUp() {
    let keyboard = Keyboard()
    let fixture = fixture(keyboard)
    fixture.model.pointerEntered()
    keyboard.isHeld = false
    fixture.model.shortcutReleased()
    fixture.clock.advance(by: .seconds(5))
    #expect(fixture.model.isShown)
  }

  @Test func aReleaseAfterHidingDoesNotBringItBack() {
    let keyboard = Keyboard()
    keyboard.isHeld = false
    let fixture = fixture(keyboard)
    fixture.clock.advance(by: linger)
    fixture.model.shortcutReleased()
    fixture.clock.advance(by: linger)
    #expect(!fixture.model.isShown)
    #expect(fixture.visibility == [false])
  }

  @Test func hoveringATileNamesItsWindowAndLeavingClearsIt() throws {
    let fixture = fixture(Keyboard())
    let cell = try fixture.model.cell(3)
    fixture.model.pointerEntered()
    fixture.model.pointerMoved(to: CGPoint(x: cell.rect.midX, y: cell.rect.midY))
    #expect(fixture.model.hoveredWindow == WindowID(3))
    fixture.model.pointerMoved(to: CGPoint(x: 1, y: Metrics.Minimap.panelHeight - 1))
    #expect(fixture.model.hoveredWindow == nil)
    fixture.model.pointerMoved(to: CGPoint(x: cell.rect.midX, y: cell.rect.midY))
    fixture.model.pointerExited()
    #expect(fixture.model.hoveredWindow == nil)
  }
}
