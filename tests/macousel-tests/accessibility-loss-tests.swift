import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct AccessibilityLossTests {
  private func tiledRow(
    in fixture: ControllerFixture
  ) -> (row: [FakeWindow], originals: [CGWindowID: CGRect], tiled: [CGWindowID: CGRect]) {
    let row = fixture.openRow(3)
    let originals = fixture.frames(of: row)
    fixture.launch()
    return (row, originals, fixture.frames(of: row))
  }

  @Test func losingAccessKeepsTheStatusHonestAndReleasesTheSystem() async throws {
    let fixture = try ControllerFixture {
      $0.swipeGestureEnabled = true
    }
    _ = tiledRow(in: fixture)

    fixture.environment.isAccessibilityGranted = false

    #expect(await fixture.becomes { fixture.manager.status == .needsPermission })
    #expect(fixture.shortcuts.boundHotkeys.isEmpty)
    #expect(!fixture.gestures.isScrolling)
    #expect(fixture.gestures.swipeFingerCount == nil)
    #expect(!fixture.crashRecovery.isArmed)
    #expect(fixture.environment.accessibilityRequests == 1)
  }

  @Test func losingAccessKeepsTheSavedOriginalFrames() async throws {
    let suite = try IsolatedDefaults()
    let fixture = try ControllerFixture(suite: suite)
    _ = tiledRow(in: fixture)

    fixture.environment.isAccessibilityGranted = false

    #expect(await fixture.becomes { fixture.manager.status == .needsPermission })
    #expect(suite.defaults.data(forKey: "originalFrames") != nil)
  }

  @Test func quittingWhileAccessIsMissingKeepsTheSavedFrames() async throws {
    let suite = try IsolatedDefaults()
    let fixture = try ControllerFixture(suite: suite)
    let (row, originals, _) = tiledRow(in: fixture)
    fixture.environment.isAccessibilityGranted = false
    #expect(await fixture.becomes { fixture.manager.status == .needsPermission })

    fixture.quit()

    let restorer = WindowRestorer(defaults: suite.defaults, bootSession: "boot-1")
    restorer.restoreSaved(row, on: [fixture.display])
    #expect(fixture.frames(of: row) == originals)
  }

  @Test func quittingRightAfterRevocationKeepsTheSavedFrames() throws {
    let suite = try IsolatedDefaults()
    let fixture = try ControllerFixture(suite: suite)
    let (row, originals, _) = tiledRow(in: fixture)
    fixture.environment.isAccessibilityGranted = false

    fixture.quit()

    let restorer = WindowRestorer(defaults: suite.defaults, bootSession: "boot-1")
    restorer.restoreSaved(row, on: [fixture.display])
    #expect(fixture.frames(of: row) == originals)
  }

  @Test func regainingAccessRestoresSavedFramesBeforeTilingAgain() async throws {
    let fixture = try ControllerFixture()
    let (row, originals, tiled) = tiledRow(in: fixture)
    fixture.environment.isAccessibilityGranted = false
    #expect(await fixture.becomes { fixture.manager.status == .needsPermission })

    fixture.environment.isAccessibilityGranted = true

    #expect(await fixture.becomes { fixture.manager.status == .running })
    #expect(await fixture.becomes { fixture.frames(of: row) == tiled })
    for window in row {
      let original = try #require(originals[window.id])
      let restoredAt = try #require(window.framesSet.lastIndex(of: original))
      let tiledAt = try #require(window.framesSet.lastIndex(of: tiled[window.id] ?? .zero))
      #expect(restoredAt < tiledAt)
    }
    #expect(fixture.crashRecovery.isArmed)
    #expect(!fixture.shortcuts.boundHotkeys.isEmpty)
  }

  @Test func accessLossIsNoticedAgainAfterRegaining() async throws {
    let fixture = try ControllerFixture()
    _ = tiledRow(in: fixture)
    fixture.environment.isAccessibilityGranted = false
    #expect(await fixture.becomes { fixture.manager.status == .needsPermission })
    fixture.environment.isAccessibilityGranted = true
    #expect(await fixture.becomes { fixture.manager.status == .running })

    fixture.environment.isAccessibilityGranted = false

    #expect(await fixture.becomes { fixture.manager.status == .needsPermission })
    #expect(fixture.environment.accessibilityRequests == 2)
  }
}
