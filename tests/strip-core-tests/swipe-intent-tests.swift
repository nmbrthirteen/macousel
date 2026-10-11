import Testing

@testable import StripCore

struct SwipeIntentTests {
  private let anchors = [0.0, 400, 800, 1200, 1600]
  private let usable = 1000.0

  @Test func aShortSlowSwipeHasNoIntent() {
    let intent = SwipeIntent(travel: 100, velocity: 50, usableWidth: usable)
    #expect(intent == .none)
    #expect(intent.restingIndex(among: anchors, from: 800, projected: 830) == 2)
  }

  @Test func travelPastTheThresholdAdvancesOneColumn() {
    let intent = SwipeIntent(travel: 120, velocity: 0, usableWidth: usable)
    #expect(intent == .forward)
    #expect(intent.restingIndex(among: anchors, from: 800, projected: 830) == 3)
  }

  @Test func travelJustBelowTheThresholdHasNoIntent() {
    #expect(SwipeIntent(travel: 119, velocity: 0, usableWidth: usable) == .none)
    #expect(SwipeIntent(travel: -119, velocity: 0, usableWidth: usable) == .none)
  }

  @Test func aFastFlickBelowTheTravelThresholdAdvancesOneColumn() {
    let intent = SwipeIntent(travel: 30, velocity: 500, usableWidth: usable)
    #expect(intent == .forward)
    #expect(intent.restingIndex(among: anchors, from: 800, projected: 810) == 3)
  }

  @Test func aFlickSlowerThanTheThresholdHasNoIntent() {
    #expect(SwipeIntent(travel: 30, velocity: 400, usableWidth: usable) == .none)
  }

  @Test func backwardIntentMovesOneColumnTowardTheStart() {
    let intent = SwipeIntent(travel: -150, velocity: -100, usableWidth: usable)
    #expect(intent == .backward)
    #expect(intent.restingIndex(among: anchors, from: 800, projected: 780) == 1)
  }

  @Test func aLongThrowGoesAsFarAsTheProjection() {
    let intent = SwipeIntent(travel: 500, velocity: 3000, usableWidth: usable)
    #expect(intent.restingIndex(among: anchors, from: 400, projected: 1600) == 4)
  }

  @Test func intentNeverReversesDirection() {
    let forward = SwipeIntent.forward
    #expect(forward.restingIndex(among: anchors, from: 800, projected: 0) == 3)
    let backward = SwipeIntent.backward
    #expect(backward.restingIndex(among: anchors, from: 800, projected: 1600) == 1)
  }

  @Test func theFlickDirectionWinsOverAnOppositeTravel() {
    #expect(SwipeIntent(travel: 300, velocity: -600, usableWidth: usable) == .backward)
  }

  @Test func intentStopsAtTheEnds() {
    #expect(SwipeIntent.forward.restingIndex(among: anchors, from: 1600, projected: 1600) == 4)
    #expect(SwipeIntent.backward.restingIndex(among: anchors, from: 0, projected: 0) == 0)
  }

  @Test func noAnchorsGivesNoResult() {
    #expect(SwipeIntent.forward.restingIndex(among: [], from: 0, projected: 0) == nil)
  }

  @Test func zeroTravelHasNoIntentEvenOnAZeroWidthViewport() {
    #expect(SwipeIntent(travel: 0, velocity: 0, usableWidth: 0) == .none)
  }
}
