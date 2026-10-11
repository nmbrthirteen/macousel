import Testing

@testable import Macousel

@MainActor
struct MinimapHoverTests {
  private let linger = OverlayTiming.minimapLinger

  private func fixture() -> MinimapModelFixture {
    MinimapModelFixture(snapshot: MinimapSnapshots.strip(columns: 4))
  }

  @Test func theMinimapHidesAfterTheLinger() {
    let fixture = fixture()
    fixture.clock.advance(by: linger - .milliseconds(1))
    #expect(fixture.model.isShown)
    fixture.clock.advance(by: .milliseconds(1))
    #expect(!fixture.model.isShown)
    #expect(fixture.visibility == [false])
  }

  @Test func hoveringKeepsItOnScreen() {
    let fixture = fixture()
    fixture.model.pointerEntered()
    fixture.clock.advance(by: .seconds(30))
    #expect(fixture.model.isShown)
    #expect(fixture.visibility.isEmpty)
  }

  @Test func leavingStartsTheTimerAgain() {
    let fixture = fixture()
    fixture.model.pointerEntered()
    fixture.clock.advance(by: .seconds(5))
    fixture.model.pointerExited()
    fixture.clock.advance(by: linger - .milliseconds(1))
    #expect(fixture.model.isShown)
    fixture.clock.advance(by: .milliseconds(1))
    #expect(!fixture.model.isShown)
  }

  @Test func aTimerStartedBeforeTheHoverDoesNotHideItAfterTheHoverEnds() {
    let fixture = fixture()
    fixture.clock.advance(by: .milliseconds(500))
    fixture.model.pointerEntered()
    fixture.model.pointerExited()
    fixture.clock.advance(by: .milliseconds(400))
    #expect(fixture.model.isShown)
    fixture.clock.advance(by: .milliseconds(500))
    #expect(!fixture.model.isShown)
  }

  @Test func aNewSnapshotRestartsTheTimer() {
    let fixture = fixture()
    fixture.clock.advance(by: .milliseconds(600))
    fixture.model.show(MinimapSnapshots.strip(columns: 4, focused: 1), update: .animated)
    fixture.clock.advance(by: .milliseconds(600))
    #expect(fixture.model.isShown)
    fixture.clock.advance(by: .milliseconds(300))
    #expect(!fixture.model.isShown)
  }

  @Test func aNewSnapshotWhileHoveringKeepsItOnScreen() {
    let fixture = fixture()
    fixture.model.pointerEntered()
    fixture.model.show(MinimapSnapshots.strip(columns: 4, focused: 2), update: .animated)
    fixture.clock.advance(by: .seconds(10))
    #expect(fixture.model.isShown)
  }

  @Test func hoveringAFadingMinimapBringsItBack() {
    let fixture = fixture()
    fixture.clock.advance(by: linger)
    fixture.model.pointerEntered()
    #expect(fixture.model.isShown)
    #expect(fixture.visibility == [false, true])
  }

  @Test func hidingCancelsThePendingTimerAndResetsThePointer() {
    let fixture = fixture()
    fixture.model.pointerEntered()
    fixture.model.hide()
    #expect(!fixture.model.isShown)
    #expect(!fixture.model.isPointerInside)
    fixture.model.show(MinimapSnapshots.strip(columns: 4), update: .immediate)
    fixture.clock.advance(by: linger)
    #expect(!fixture.model.isShown)
  }
}
