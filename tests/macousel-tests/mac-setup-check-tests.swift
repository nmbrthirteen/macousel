import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct MacSetupCheckTests {
  private func trackpad(_ values: [String: Int] = [:]) throws -> SystemDefaults {
    let suite = try IsolatedDefaults()
    for (key, value) in values { suite.defaults.set(value, forKey: key) }
    return SystemDefaults(defaults: suite.defaults)
  }

  private func windowManager(_ values: [String: Bool] = [:]) throws -> SystemDefaultsReaders {
    let suite = try IsolatedDefaults()
    for (key, value) in values { suite.defaults.set(value, forKey: key) }
    var readers = SystemDefaultsReaders()
    readers.windowManager = SystemDefaults(defaults: suite.defaults)
    return readers
  }

  private func swipeCheck(
    _ trackpads: [SystemDefaults], fingers: Int = 4, enabled: Bool = true
  ) -> SetupCheck? {
    SwipeGestureCheck(trackpads: trackpads, isSwipeEnabled: enabled, fingers: fingers).check
  }

  @Test func swipeCheckPassesWhenTheTrackpadKeysAreAbsent() throws {
    let check = try #require(swipeCheck([try trackpad(), try trackpad()]))
    #expect(check.isPassing)
    #expect(check.title == "The swipe gesture is free")
  }

  @Test func swipeCheckNeedsAttentionWhenMacOSUsesTheFourFingerSwipe() throws {
    let check = try #require(
      swipeCheck([try trackpad(["TrackpadFourFingerHorizSwipeGesture": 2])]))
    #expect(!check.isPassing)
    #expect(check.title == "macOS uses the same swipe")
    #expect(
      check.detail
        == "macOS switches desktops with the same swipe. Change it in System Settings > Trackpad > More Gestures. Turn off Swipe between full-screen applications or set it to the other finger count."
    )
  }

  @Test func swipeCheckReadsTheThreeFingerKeyForThreeFingers() throws {
    let trackpads = [try trackpad(["TrackpadThreeFingerHorizSwipeGesture": 2])]
    #expect(try #require(swipeCheck(trackpads, fingers: 3)).isPassing == false)
    #expect(try #require(swipeCheck(trackpads, fingers: 4)).isPassing)
  }

  @Test func swipeCheckLooksAtBothTrackpadDomains() throws {
    let check = try #require(
      swipeCheck([try trackpad(), try trackpad(["TrackpadFourFingerHorizSwipeGesture": 2])]))
    #expect(!check.isPassing)
  }

  @Test func swipeCheckPassesWhenMacOSHasTheGestureOffOrSetToAnotherValue() throws {
    for value in [0, 1, 3] {
      let check = try #require(
        swipeCheck([try trackpad(["TrackpadFourFingerHorizSwipeGesture": value])]))
      #expect(check.isPassing)
    }
  }

  @Test func swipeCheckIsHiddenWhenTheSwipeGestureIsOff() throws {
    let trackpads = [try trackpad(["TrackpadFourFingerHorizSwipeGesture": 2])]
    #expect(swipeCheck(trackpads, enabled: false) == nil)
  }

  @Test func optionDragTilingNeedsAttentionWhenTheKeyIsAbsent() throws {
    let check = SystemSettingsChecks(readers: try windowManager()).optionDragTiling
    #expect(!check.isPassing)
    #expect(check.title == "Option-drag tiling is on")
  }

  @Test func optionDragTilingPassesWhenTurnedOff() throws {
    let readers = try windowManager(["EnableTilingOptionAccelerator": false])
    #expect(SystemSettingsChecks(readers: readers).optionDragTiling.isPassing)
  }

  @Test func optionDragTilingNeedsAttentionWhenTurnedOn() throws {
    let readers = try windowManager(["EnableTilingOptionAccelerator": true])
    #expect(!SystemSettingsChecks(readers: readers).optionDragTiling.isPassing)
  }

  @Test func edgeTilingStillNeedsBothEdgeSettingsOff() throws {
    let off = try windowManager([
      "EnableTilingByEdgeDrag": false, "EnableTopTilingByEdgeDrag": false,
    ])
    let half = try windowManager(["EnableTilingByEdgeDrag": false])
    #expect(SystemSettingsChecks(readers: off).edgeTiling.isPassing)
    #expect(!SystemSettingsChecks(readers: half).edgeTiling.isPassing)
  }

  @Test func systemSettingsChecksIncludeTheOptionDragCheck() throws {
    let ids = SystemSettingsChecks(readers: try windowManager()).all.map(\.id)
    #expect(ids.contains("option-drag-tiling"))
    #expect(Set(ids).count == ids.count)
  }

  private func locationCheck(_ path: String) -> SetupCheck {
    InstallLocationCheck(
      bundleURL: URL(fileURLWithPath: path), homeDirectory: URL(fileURLWithPath: "/Users/sam")
    ).check
  }

  @Test(arguments: ["/Applications/Macousel.app", "/Users/sam/Applications/Macousel.app"])
  func installLocationPassesInApplicationsFolders(path: String) {
    #expect(locationCheck(path).isPassing)
  }

  @Test(arguments: [
    "/private/var/folders/ab/T/AppTranslocation/1234/d/Macousel.app",
    "/Volumes/Macousel 0.2/Macousel.app",
    "/Users/sam/Downloads/Macousel.app",
    "/Users/sam/Downloads/unpacked/Macousel.app",
  ])
  func installLocationNeedsAttentionInTemporaryLocations(path: String) {
    let check = locationCheck(path)
    #expect(!check.isPassing)
    #expect(check.detail.hasPrefix("macOS ties the Accessibility permission to the app's location."))
  }

  @Test func installLocationIgnoresFoldersThatOnlyStartWithDownloads() {
    #expect(locationCheck("/Users/sam/Downloads-old/Macousel.app").isPassing)
  }
}
