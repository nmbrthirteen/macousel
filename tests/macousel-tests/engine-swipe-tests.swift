import StripCore
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct EngineSwipeTests {
  private let gestures = FakeGestureInput()
  private let commands = FakeEngineCommands(log: EngineCallLog())
  private let store: PreferencesStore
  private let east = ["window", "focus", "east"]
  private let west = ["window", "focus", "west"]

  private final class Scene {
    var position: StripPosition? = StripPosition(
      columnCount: 4, focusedIndex: 1, windowsInFocusedColumn: 1)
    var isSuppressed = false
  }

  private let scene = Scene()

  init() throws {
    store = PreferencesStore(defaults: try IsolatedDefaults().defaults)
  }

  private func makeSwipe() -> EngineSwipe {
    let scene = scene
    return EngineSwipe(
      gestures: gestures, store: store, commands: commands, position: { scene.position },
      isSuppressed: { scene.isSuppressed })
  }

  private func settle() async {
    for _ in 0..<50 { await Task.yield() }
  }

  private func swipe(_ shares: [Double]) async {
    for (index, share) in shares.enumerated() {
      gestures.onSwipe?(share, index == 0 ? .began : .changed)
    }
    gestures.onSwipe?(0, .ended)
    await settle()
  }

  @Test func listensWithTheChosenFingerCountWhileRunning() {
    store.preferences.swipeFingers = 3
    let swipe = makeSwipe()

    swipe.configure(isRunning: true)
    #expect(gestures.swipeFingerCount == 3)

    swipe.stop()
    #expect(gestures.swipeFingerCount == nil)
  }

  @Test func staysOffWhenPausedDisabledOrFree() {
    let swipe = makeSwipe()

    swipe.configure(isRunning: false)
    #expect(gestures.swipeFingerCount == nil)

    store.preferences.swipeGestureEnabled = false
    swipe.configure(isRunning: true)
    #expect(gestures.swipeFingerCount == nil)

    store.preferences.swipeGestureEnabled = true
    store.preferences.swipeStep = SwipeStep.free
    swipe.configure(isRunning: true)
    #expect(gestures.swipeFingerCount == nil)
  }

  @Test func aSwipeToTheLeftFocusesTheNextColumnOnce() async {
    let swipe = makeSwipe()
    swipe.configure(isRunning: true)

    await self.swipe([-0.03, -0.04, -0.05])

    #expect(commands.sent == [east])
  }

  @Test func aSwipeToTheRightFocusesThePreviousColumn() async {
    let swipe = makeSwipe()
    swipe.configure(isRunning: true)

    await self.swipe([0.08])

    #expect(commands.sent == [west])
  }

  @Test func aLongSwipeKeepsStepping() async {
    let swipe = makeSwipe()
    swipe.configure(isRunning: true)

    await self.swipe([-0.08, -0.25])

    #expect(commands.sent == [east, east])
  }

  @Test func stepsStopAtTheEndOfTheStrip() async {
    let swipe = makeSwipe()
    swipe.configure(isRunning: true)

    await self.swipe([-0.9])
    #expect(commands.sent == [east, east])

    await self.swipe([0.9])
    #expect(commands.sent.filter { $0 == west }.count == 1)
  }

  @Test func reversingTheDirectionFlipsTheStep() async {
    store.preferences.reversesSwipeDirection = true
    let swipe = makeSwipe()
    swipe.configure(isRunning: true)

    await self.swipe([-0.08])

    #expect(commands.sent == [west])
  }

  @Test func sensitivityScalesTheTravel() async {
    store.preferences.swipeSensitivity = 2
    let swipe = makeSwipe()
    swipe.configure(isRunning: true)

    await self.swipe([-0.035])

    #expect(commands.sent == [east])
  }

  @Test func eachSwipeStartsFresh() async {
    let swipe = makeSwipe()
    swipe.configure(isRunning: true)

    await self.swipe([-0.04])
    await self.swipe([-0.04])

    #expect(commands.sent.isEmpty)
  }

  @Test func nothingMovesWhileTheOverviewIsOpenOrTheStripIsUnknown() async {
    let swipe = makeSwipe()
    swipe.configure(isRunning: true)

    scene.isSuppressed = true
    await self.swipe([-0.2])
    scene.isSuppressed = false
    scene.position = nil
    await self.swipe([-0.2])

    #expect(commands.sent.isEmpty)
  }
}
