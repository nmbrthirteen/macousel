import CoreGraphics
import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ReverseSwipeTests {
  private func expectedFrames(offset: Double) -> [CGWindowID: CGRect] {
    var expected = ExpectedStrip(columns: [1, 2, 3, 4])
    expected.strip.scrollOffset = offset
    return expected.frames
  }

  @Test func swipeDirectionIsNotReversedByDefault() {
    #expect(!Preferences().reversesSwipeDirection)
  }

  @Test func missingSettingDecodesAsNotReversed() throws {
    let decoded = try JSONDecoder().decode(Preferences.self, from: Data("{}".utf8))
    #expect(!decoded.reversesSwipeDirection)
  }

  @Test func reversedScrollMovesTheStripTheOtherWay() throws {
    let fixture = try ControllerFixture { $0.reversesSwipeDirection = true }
    let row = fixture.openRow(4)
    fixture.launch()

    fixture.gestures.onScroll?(120, .began)

    #expect(fixture.frames(of: row) == expectedFrames(offset: 120))
  }

  @Test func scrollKeepsItsDirectionWhenNotReversed() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()

    fixture.gestures.onScroll?(-120, .began)

    #expect(fixture.frames(of: row) == expectedFrames(offset: 120))
  }

  @Test func reversedSwipeMovesTheStripTheOtherWay() throws {
    let fixture = try ControllerFixture { $0.reversesSwipeDirection = true }
    let row = fixture.openRow(4)
    fixture.launch()
    let usableWidth = fixture.display.visibleFrame.width - 2 * fixture.config.outerGap

    fixture.gestures.onSwipe?(0.1, .began)

    #expect(fixture.frames(of: row) == expectedFrames(offset: 0.1 * usableWidth * 1.6))
  }

  @Test func swipeKeepsItsDirectionWhenNotReversed() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    let usableWidth = fixture.display.visibleFrame.width - 2 * fixture.config.outerGap

    fixture.gestures.onSwipe?(-0.1, .began)

    #expect(fixture.frames(of: row) == expectedFrames(offset: 0.1 * usableWidth * 1.6))
  }

  @Test func togglingTheSettingAppliesToTheNextGesture() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(4)
    fixture.launch()
    fixture.store.preferences.reversesSwipeDirection = true

    fixture.gestures.onScroll?(120, .began)

    #expect(fixture.frames(of: row) == expectedFrames(offset: 120))
  }
}
