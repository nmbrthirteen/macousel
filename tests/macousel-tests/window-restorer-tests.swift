import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct WindowRestorerTests {
  private let displays = [Display.fake()]
  private let original = CGRect(x: 100, y: 100, width: 400, height: 300)
  private let moved = CGRect(x: 600, y: 200, width: 300, height: 500)

  private func window(_ id: CGWindowID, app: FakeApp = .editor) -> FakeWindow {
    FakeWindow(id: id, app: app, title: "Window \(id)", frame: original)
  }

  @Test func originalFramesSurviveASimulatedRelaunch() throws {
    let suite = try IsolatedDefaults()
    let tracked = window(1)
    WindowRestorer(defaults: suite.defaults, bootSession: "boot-1").remember(tracked)
    tracked.frame = moved

    let relaunched = WindowRestorer(defaults: suite.defaults, bootSession: "boot-1")
    relaunched.restore([tracked], on: displays)

    #expect(tracked.frame == original)
  }

  @Test func firstRememberedFrameWinsOverLaterOnes() throws {
    let suite = try IsolatedDefaults()
    let tracked = window(1)
    let restorer = WindowRestorer(defaults: suite.defaults, bootSession: "boot-1")
    restorer.remember(tracked)
    tracked.frame = moved

    restorer.remember(tracked)
    restorer.restore([tracked], on: displays)

    #expect(tracked.frame == original)
  }

  @Test func recycledWindowIDFromAnotherProcessIsRememberedAgain() throws {
    let suite = try IsolatedDefaults()
    let restorer = WindowRestorer(defaults: suite.defaults, bootSession: "boot-1")
    restorer.remember(window(1, app: .editor))
    let reused = window(1, app: .browser)
    reused.frame = moved

    restorer.remember(reused)
    reused.frame = original
    restorer.restore([reused], on: displays)

    #expect(reused.frame == moved)
  }

  @Test func framesAreClearedAfterForgetAll() throws {
    let suite = try IsolatedDefaults()
    let tracked = window(1)
    let restorer = WindowRestorer(defaults: suite.defaults, bootSession: "boot-1")
    restorer.remember(tracked)
    tracked.frame = moved

    restorer.forgetAll()
    WindowRestorer(defaults: suite.defaults, bootSession: "boot-1").restore([tracked], on: displays)

    #expect(tracked.frame == moved)
  }

  @Test func retainingOnlyLiveWindowsDropsTheRest() throws {
    let suite = try IsolatedDefaults()
    let kept = window(1)
    let gone = window(2)
    let restorer = WindowRestorer(defaults: suite.defaults, bootSession: "boot-1")
    restorer.remember(kept)
    restorer.remember(gone)
    kept.frame = moved
    gone.frame = moved

    restorer.retain(only: [1])
    let relaunched = WindowRestorer(defaults: suite.defaults, bootSession: "boot-1")
    relaunched.restore([kept, gone], on: displays)

    #expect(kept.frame == original)
    #expect(gone.frame == moved)
  }

  @Test func unreachableFrameIsClampedOntoTheNearestDisplay() throws {
    let suite = try IsolatedDefaults()
    let stranded = window(1)
    stranded.frame = CGRect(x: 4000, y: 100, width: 400, height: 300)
    let restorer = WindowRestorer(defaults: suite.defaults, bootSession: "boot-1")
    restorer.remember(stranded)

    restorer.restore([stranded], on: displays)

    let visible = displays[0].visibleFrame
    #expect(visible.contains(try #require(stranded.frame)))
  }

  @Test func windowsWithoutARememberedFrameKeepTheirCurrentFrame() throws {
    let suite = try IsolatedDefaults()
    let tracked = window(1)
    tracked.frame = moved

    WindowRestorer(defaults: suite.defaults, bootSession: "boot-1").restore([tracked], on: displays)

    #expect(tracked.frame == moved)
  }

  @Test func controllerPersistsOriginalFramesWhileTiling() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    let originals = fixture.frames(of: row)
    fixture.launch()
    #expect(fixture.frames(of: row) != originals)

    WindowRestorer(defaults: fixture.suite.defaults, bootSession: "boot-1").restore(row, on: fixture.environment.displays)

    #expect(fixture.frames(of: row) == originals)
  }

  @Test func controllerClearsOriginalFramesOnShutdown() throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.quit()
    row[0].frame = moved

    WindowRestorer(defaults: fixture.suite.defaults, bootSession: "boot-1").restore(row, on: fixture.environment.displays)

    #expect(row[0].frame == moved)
  }

  @Test func controllerForgetsFramesOfWindowsThatClosed() async throws {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(3)
    fixture.launch()
    fixture.source.close(row[2])
    let marker = fixture.open(4, app: .browser, atX: 900)
    let expected = ExpectedStrip(columns: [1, 4, 2])
    #expect(await fixture.becomes { marker.frame == expected.frame(of: 4) })
    row[2].frame = moved

    let relaunched = WindowRestorer(defaults: fixture.suite.defaults, bootSession: "boot-1")
    relaunched.restore([row[2]], on: fixture.environment.displays)

    #expect(row[2].frame == moved)
  }
}
