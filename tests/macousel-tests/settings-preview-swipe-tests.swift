import Foundation
import StripCore
import Testing

@testable import Macousel

@MainActor
struct SettingsPreviewSwipeTests {
  @MainActor private final class Observed {
    var progressAtEachSleep: [Double] = []
    var durations: [Duration] = []
  }

  private let usableWidth = 1264.0

  @Test(arguments: [3, 4])
  func trackpadShowsOneDotPerFinger(count: Int) {
    let diagram = SwipeDiagram(fingerCount: count, reversesDirection: false)
    #expect(diagram.fingerCenters.count == count)
  }

  @Test func fingerDotsSitSymmetricallyAroundTheCentre() {
    let centers = SwipeDiagram(fingerCount: 4, reversesDirection: false).fingerCenters
    #expect(abs(centers[0].x + centers[3].x - 1) < 0.0001)
    #expect(abs(centers[1].x + centers[2].x - 1) < 0.0001)
    #expect(centers.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
  }

  @Test func fingersAlwaysMoveLeft() {
    #expect(SwipeDiagram(fingerCount: 3, reversesDirection: false).fingerDirection == .left)
    #expect(SwipeDiagram(fingerCount: 3, reversesDirection: true).fingerDirection == .left)
  }

  @Test func stripFollowsTheFingersUnlessReversed() {
    #expect(SwipeDiagram(fingerCount: 4, reversesDirection: false).stripDirection == .left)
    #expect(SwipeDiagram(fingerCount: 4, reversesDirection: true).stripDirection == .right)
  }

  @Test func captionNamesTheDirectionTheStripMoves() {
    #expect(SwipeDiagram(fingerCount: 4, reversesDirection: false).stripCaption == "The strip moves left")
    #expect(SwipeDiagram(fingerCount: 4, reversesDirection: true).stripCaption == "The strip moves right")
  }

  @Test func scrollOffsetGrowsWhenTheStripMovesLeftAndShrinksWhenReversed() {
    let normal = SwipeDiagram(fingerCount: 4, reversesDirection: false)
    let reversed = SwipeDiagram(fingerCount: 4, reversesDirection: true)
    let start = PreviewMetrics.Swipe.startOffset
    #expect(normal.scrollOffset(progress: 0, sensitivity: 1, usableWidth: usableWidth) == start)
    #expect(normal.scrollOffset(progress: 1, sensitivity: 1, usableWidth: usableWidth) > start)
    #expect(reversed.scrollOffset(progress: 1, sensitivity: 1, usableWidth: usableWidth) < start)
  }

  @Test func sensitivityScalesTheTravelOfTheSameSwipe() {
    let diagram = SwipeDiagram(fingerCount: 4, reversesDirection: false)
    let start = PreviewMetrics.Swipe.startOffset
    let slow = diagram.scrollOffset(progress: 1, sensitivity: 0.5, usableWidth: usableWidth) - start
    let fast = diagram.scrollOffset(progress: 1, sensitivity: 2, usableWidth: usableWidth) - start
    #expect(abs(fast / slow - 4) < 0.0001)
  }

  @Test func sampleSwipeTravelsTheEngineDistanceForAQuarterPad() {
    let diagram = SwipeDiagram(fingerCount: 4, reversesDirection: false)
    let travel =
      diagram.scrollOffset(progress: 1, sensitivity: 1, usableWidth: usableWidth)
      - PreviewMetrics.Swipe.startOffset
    #expect(abs(travel - 0.25 * usableWidth * 2.4) < 0.001)
  }

  @Test func playRestsThenSwipesThenReturns() async {
    let observed = Observed()
    var demo: SwipeDemo?
    demo = SwipeDemo { duration in
      observed.progressAtEachSleep.append(demo?.progress ?? -1)
      observed.durations.append(duration)
    }
    await demo?.play()
    #expect(observed.progressAtEachSleep == [0, 1])
    #expect(observed.durations == [.milliseconds(150), .milliseconds(1400)])
    #expect(demo?.progress == 0)
  }

  @Test func reduceMotionShowsTheFinishedSwipeWithoutAnimating() {
    let demo = SwipeDemo { _ in }
    demo.replay(after: .zero, reduceMotion: true)
    #expect(demo.progress == 1)
  }

  @Test func stopReturnsTheStripToRest() {
    let demo = SwipeDemo { _ in }
    demo.replay(after: .zero, reduceMotion: true)
    demo.stop()
    #expect(demo.progress == 0)
  }
}
