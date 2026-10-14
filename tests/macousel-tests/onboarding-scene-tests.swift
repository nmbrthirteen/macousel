import CoreGraphics
import Testing

@testable import Macousel

@MainActor
struct OnboardingSceneTests {
  private typealias Scene = OnboardingSceneMetrics

  private func strip(focused: Int = 0) -> SceneStrip {
    SceneStrip(styles: SceneWindowStyle.allCases, widthShares: [0.5, 0.6, 0.45, 0.5, 0.55], focused: focused)
  }

  private func isVisible(_ rect: CGRect) -> Bool {
    rect.minX >= 0 && rect.maxX <= Scene.size.width
  }

  @Test func theFocusedColumnStaysOnScreenAcrossTheStrip() {
    var scene = strip()
    for index in scene.columns.indices {
      scene.focus(index)
      let focused = scene.windows.first(where: \.isFocused)
      #expect(focused.map { isVisible($0.rect) } == true)
    }
  }

  @Test func focusingBackToTheFirstColumnScrollsHome() {
    var scene = strip()
    scene.focus(4)
    scene.focus(0)
    #expect(abs(scene.windows[0].rect.minX - Scene.edgeGap) < 0.001)
  }

  @Test func movingAWindowSwapsItWithItsNeighbour() {
    var scene = strip(focused: 2)
    scene.moveFocused(by: -1)
    #expect(scene.columns.map(\.window) == [0, 2, 1, 3, 4])
    #expect(scene.position.focusedIndex == 1)
  }

  @Test func theOverviewFitsEveryWindowOnScreen() {
    var scene = strip()
    scene.isOverview = true
    #expect(scene.windows.allSatisfy { isVisible($0.rect) })
  }

  @Test func everySceneShowsTheKeysItPresses() {
    let keys: (Action) -> String? = { _ in "keys" }
    for frames in [
      OnboardingScenes.welcome(keys: keys), OnboardingScenes.access(keys: keys),
      OnboardingScenes.shortcuts(keys: keys),
    ] {
      #expect(frames.contains { $0.keys == "keys" })
      #expect(frames.allSatisfy { $0.windows.count == SceneWindowStyle.allCases.count })
    }
  }

  @Test func theAccessSceneClicksTheToggle() {
    let frames = OnboardingScenes.access(keys: { _ in nil })
    let click = frames.first { $0.cursor?.isPressed == true }
    #expect(click?.cursor?.point == Scene.toggleCenter)
    #expect(frames.contains { $0.accessToggle == true })
  }

  @Test func theSceneMovesWithoutJumpsBetweenBeats() {
    let keys: (Action) -> String? = { _ in "keys" }
    for frames in [
      OnboardingScenes.welcome(keys: keys), OnboardingScenes.access(keys: keys),
      OnboardingScenes.shortcuts(keys: keys), OnboardingScenes.menuBar(),
    ] {
      let timeline = SceneTimeline(frames: frames)
      var boundary = 0.0
      for frame in frames.dropLast() {
        boundary += frame.hold.timeInterval
        let before = timeline.pose(at: boundary - 0.0001)
        let after = timeline.pose(at: boundary + 0.0001)
        for window in after.windows {
          let start = before.windows.first { $0.id == window.id }?.rect ?? window.rect
          #expect(abs(window.rect.minX - start.minX) < 1)
          #expect(abs(window.rect.width - start.width) < 1)
        }
        #expect(abs(after.toggle - before.toggle) < 0.05)
        #expect(abs(after.card - before.card) < 0.05)
      }
    }
  }

  @Test func theMenuBarSceneClicksTheMacouselItemAndPicksSettings() {
    let frames = OnboardingScenes.menuBar()
    let click = frames.first { $0.cursor?.isPressed == true }
    #expect(click.map { Scene.appItem.contains($0.cursor!.point) } == true)
    #expect(frames.contains { $0.menu?.highlighted == Scene.settingsItem })
  }

  @Test func theMacouselItemSitsLeftOfTheStatusItems() {
    #expect(Scene.appItem.minX > 0)
    #expect(Scene.menuFrame.maxX < Scene.size.width)
  }

  @Test func theSceneFadesAtTheLoop() {
    let timeline = SceneTimeline(frames: OnboardingScenes.welcome(keys: { _ in nil }))
    #expect(timeline.pose(at: 0).stage == 0)
    #expect(timeline.pose(at: timeline.duration / 2).stage == 1)
    #expect(timeline.pose(at: timeline.duration - 0.001).stage < 0.01)
  }

  @Test func theEasingSettlesWithinAHold() {
    #expect(SceneTimeline.eased(0) == 0)
    #expect(SceneTimeline.eased(SceneTimeline.response) > 0.98)
  }

  @Test func reducedMotionHoldsTheRestingFrame() {
    let frames = OnboardingScenes.access(keys: { _ in nil })
    let timeline = SceneTimeline(frames: frames, restingIndex: 4)
    #expect(timeline.restingPose == ScenePose(frames[4]))
  }
}
