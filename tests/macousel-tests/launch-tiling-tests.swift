import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct LaunchTilingTests {
  @Test func existingWindowsTileLeftToRightByOnScreenPosition() throws {
    let fixture = try ControllerFixture()
    let right = fixture.open(1, atX: 700)
    let left = fixture.open(2, atX: 100)
    let middle = fixture.open(3, atX: 400)

    fixture.launch()

    let expected = ExpectedStrip(columns: [2, 3, 1])
    #expect(fixture.frames(of: [left, middle, right]) == expected.frames)
  }

  @Test func launchWaitsForAccessibilityBeforeTiling() throws {
    let fixture = try ControllerFixture()
    let window = fixture.open(1, atX: 100)
    fixture.environment.isAccessibilityGranted = false

    fixture.launch()

    #expect(fixture.environment.accessibilityRequests == 1)
    #expect(fixture.manager.status == .needsPermission)
    #expect(window.framesSet.isEmpty)
    #expect(!fixture.source.isStarted)
  }

  @Test func launchStartsTheSourceAndObservesTheEnvironment() throws {
    let fixture = try ControllerFixture()

    fixture.launch()

    #expect(fixture.manager.status == .running)
    #expect(fixture.source.isStarted)
    #expect(fixture.environment.isObserving)
  }

  @Test func launchFocusesTheColumnOfTheSystemFocusedWindow() throws {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let first = fixture.open(1, atX: 100)
    let second = fixture.open(2, atX: 400, activating: true)

    fixture.launch()

    #expect(fixture.windowShowingFocusBorder(among: [first, second]) === second)
  }

  @Test func nonTileableWindowsAreNeverTiled() throws {
    let fixture = try ControllerFixture()
    let dialog = fixture.open(1, atX: 100)
    dialog.isTileable = false
    let document = fixture.open(2, atX: 400)

    fixture.launch()

    #expect(dialog.framesSet.isEmpty)
    #expect(document.frame == ExpectedStrip(columns: [2]).frame(of: 2))
  }

  @Test func fullScreenWindowsAreNeverTiled() throws {
    let fixture = try ControllerFixture()
    let video = fixture.open(1, atX: 100)
    video.isFullScreen = true
    let document = fixture.open(2, atX: 400)

    fixture.launch()

    #expect(video.framesSet.isEmpty)
    #expect(document.frame == ExpectedStrip(columns: [2]).frame(of: 2))
  }

  @Test func floatRuleExcludesTheApp() throws {
    let fixture = try ControllerFixture {
      $0.appRules = [AppRule(bundleIdentifier: FakeApp.browser.bundleIdentifier, behavior: .float)]
    }
    let floating = fixture.open(1, app: .browser, atX: 100)
    let tiled = fixture.open(2, atX: 400)

    fixture.launch()

    #expect(floating.framesSet.isEmpty)
    #expect(tiled.frame == ExpectedStrip(columns: [2]).frame(of: 2))
  }

  @Test func widthRuleSizesTheColumnOfThatApp() throws {
    let fixture = try ControllerFixture {
      $0.appRules = [
        AppRule(bundleIdentifier: FakeApp.browser.bundleIdentifier, behavior: .width(0.25))
      ]
    }
    let editor = fixture.open(1, atX: 100)
    let browser = fixture.open(2, app: .browser, atX: 400)

    fixture.launch()

    var expected = ExpectedStrip()
    expected.append(1, .fraction(0.5))
    expected.append(2, .fraction(0.25))
    #expect(fixture.frames(of: [editor, browser]) == expected.frames)
  }

  @Test func slotRuleMovesTheColumnOfThatAppToItsPosition() throws {
    let fixture = try ControllerFixture {
      $0.layout.defaultWidth = 0.25
      $0.appRules = [AppRule(bundleIdentifier: FakeApp.browser.bundleIdentifier, behavior: .slot(1))]
    }
    let first = fixture.open(1, atX: 100)
    let second = fixture.open(2, atX: 400)
    let browser = fixture.open(3, app: .browser, atX: 700)

    fixture.launch()

    let expected = ExpectedStrip(columns: [3, 1, 2], fraction: 0.25)
    #expect(fixture.frames(of: [first, second, browser]) == expected.frames)
  }
}
