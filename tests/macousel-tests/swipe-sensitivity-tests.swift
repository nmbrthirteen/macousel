import CoreGraphics
import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct SwipeSensitivityTests {
  private func expectedFrames(offset: Double) -> [CGWindowID: CGRect] {
    var expected = ExpectedStrip(columns: [1, 2, 3, 4])
    expected.strip.scrollOffset = offset
    return expected.frames
  }

  private func usableWidth(_ fixture: ControllerFixture) -> Double {
    fixture.display.visibleFrame.width - 2 * fixture.config.outerGap
  }

  private func swipe(_ fixture: ControllerFixture, share: Double, steps: Int, spacing: Duration) {
    fixture.gestures.onSwipe?(share, .began)
    for _ in 0..<steps {
      fixture.clock.advance(by: spacing)
      fixture.gestures.onSwipe?(share, .changed)
    }
    fixture.clock.advance(by: spacing)
    fixture.gestures.onSwipe?(0, .ended)
  }

  @Test func sensitivityDefaultsToOne() {
    #expect(Preferences().swipeSensitivity == 1.0)
  }

  @Test func missingSettingDecodesAsOne() throws {
    let decoded = try JSONDecoder().decode(Preferences.self, from: Data("{}".utf8))
    #expect(decoded.swipeSensitivity == 1.0)
  }

  @Test func aMalformedSettingDecodesAsOne() throws {
    let decoded = try JSONDecoder().decode(
      Preferences.self, from: Data(#"{"swipeSensitivity": "fast"}"#.utf8))
    #expect(decoded.swipeSensitivity == 1.0)
  }

  @Test func theSettingRoundTrips() throws {
    var preferences = Preferences()
    preferences.swipeSensitivity = 1.7
    let data = try JSONEncoder().encode(preferences)
    #expect(try JSONDecoder().decode(Preferences.self, from: data).swipeSensitivity == 1.7)
  }

  @Test func theBaseTravelIsTwoPointFourUsableWidthsPerPad() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    fixture.gestures.onSwipe?(-0.1, .began)
    #expect(fixture.frames(of: row) == expectedFrames(offset: 0.1 * usableWidth(fixture) * 2.4))
  }

  @Test(arguments: [0.5, 1.0, 1.5, 2.0])
  func sensitivityScalesTheTravel(sensitivity: Double) throws {
    let fixture = try ControllerFixture { $0.swipeSensitivity = sensitivity }
    let row = fixture.openRow(4)
    fixture.launch()
    fixture.gestures.onSwipe?(-0.1, .began)
    let offset = 0.1 * usableWidth(fixture) * 2.4 * sensitivity
    #expect(fixture.frames(of: row) == expectedFrames(offset: offset))
  }

  @Test func sensitivityOutsideTheRangeIsClamped() throws {
    let fixture = try ControllerFixture { $0.swipeSensitivity = 9 }
    let row = fixture.openRow(4)
    fixture.launch()
    fixture.gestures.onSwipe?(-0.1, .began)
    #expect(fixture.frames(of: row) == expectedFrames(offset: 0.1 * usableWidth(fixture) * 4.8))
  }

  @Test func theScrollGestureIgnoresTheSensitivity() throws {
    let fixture = try ControllerFixture { $0.swipeSensitivity = 2 }
    let row = fixture.openRow(4)
    fixture.launch()
    fixture.gestures.onScroll?(-120, .began)
    #expect(fixture.frames(of: row) == expectedFrames(offset: 120))
  }

  @Test func aShortQuickSwipeAdvancesOneColumn() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    swipe(fixture, share: -0.015, steps: 2, spacing: .milliseconds(10))
    #expect(row[1].focusCount == 1)
    #expect(row[0].focusCount == 0)
  }

  @Test func aShortSlowSwipeSnapsBack() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    let initial = fixture.frames(of: row)
    swipe(fixture, share: -0.01, steps: 2, spacing: .milliseconds(150))
    #expect(fixture.frames(of: row) == initial)
    #expect(row.allSatisfy { $0.focusCount == 0 })
  }

  @Test func aSlowSwipePastTheTravelThresholdAdvancesOneColumn() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    swipe(fixture, share: -0.02, steps: 2, spacing: .milliseconds(150))
    #expect(row[1].focusCount == 1)
  }

  @Test func aQuickSwipeTheOtherWayDoesNotMoveFurtherThanTheStart() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    let initial = fixture.frames(of: row)
    swipe(fixture, share: 0.015, steps: 2, spacing: .milliseconds(10))
    #expect(fixture.frames(of: row) == initial)
  }
}
