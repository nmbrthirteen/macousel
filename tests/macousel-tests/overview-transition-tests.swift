import Testing

@testable import Macousel

@MainActor
struct OverviewTransitionTests {
  @Test func openingCapturesFirstAndShowsOnlyOnceTheCaptureIsIn() {
    var transition = OverviewTransition()

    let opening = transition.open()

    #expect(opening == .capture(generation: 1))
    #expect(transition.stage == .capturing)
    let shows = transition.captured(1)
    #expect(shows)
    #expect(transition.stage == .open)
  }

  @Test func updatesWhileCapturingOrOpenNeverStartAnotherCapture() {
    var transition = OverviewTransition()
    _ = transition.open()

    #expect(transition.open() == .update)
    _ = transition.captured(1)
    #expect(transition.open() == .update)
  }

  @Test func closingDuringTheCaptureAbandonsItAndNothingEverShows() {
    var transition = OverviewTransition()
    _ = transition.open()

    #expect(transition.close() == .abandon)
    let shows = transition.captured(1)
    #expect(!shows)
    #expect(transition.stage == .closed)
  }

  @Test func theOverlayLeavesOnlyAfterThePicturesLand() {
    var transition = OverviewTransition()
    _ = transition.open()
    _ = transition.captured(1)

    let closing = transition.close()

    #expect(closing == .collapse(generation: 2))
    #expect(transition.stage == .closing)
    #expect(transition.close() == .none)
    let leaves = transition.landed(2)
    #expect(leaves)
    #expect(transition.stage == .closed)
  }

  @Test func reopeningMidCloseExpandsAgainAndIgnoresTheOldLanding() {
    var transition = OverviewTransition()
    _ = transition.open()
    _ = transition.captured(1)
    _ = transition.close()

    #expect(transition.open() == .expand)
    let leaves = transition.landed(2)
    #expect(!leaves)
    #expect(transition.stage == .open)
  }

  @Test func aLateCaptureFromAnEarlierOpeningIsIgnored() {
    var transition = OverviewTransition()
    _ = transition.open()
    _ = transition.close()

    #expect(transition.open() == .capture(generation: 3))
    let staleShows = transition.captured(1)
    #expect(!staleShows)
    let shows = transition.captured(3)
    #expect(shows)
  }
}
