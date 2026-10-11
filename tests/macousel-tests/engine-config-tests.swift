import Testing

@testable import Macousel

@MainActor
struct EngineConfigTests {
  private func render(_ change: (inout Preferences) -> Void) -> String {
    var preferences = Preferences()
    change(&preferences)
    return EngineConfig(preferences: preferences).text
  }

  @Test func defaultPreferencesMatchTheGoldenFile() {
    #expect(EngineConfig(preferences: Preferences()).text == EngineDefaultGolden.text)
  }

  @Test func everyChangedSettingMatchesTheGoldenFile() {
    let text = EngineConfig(preferences: .everySettingChangedForTheEngine()).text

    #expect(text == EngineChangedGolden.text)
  }

  @Test func theSameInputAlwaysProducesTheSameText() {
    let preferences = Preferences.everySettingChangedForTheEngine()

    #expect(EngineConfig(preferences: preferences).text == EngineConfig(preferences: preferences).text)
  }

  @Test func halvesTheInnerGapOntoEachWindowSoNeighboursAddUpToTheGap() {
    let gaps = EngineConfigGaps(innerGap: 8, outerGap: 8)

    #expect(gaps.windowInset == 4)
    #expect(gaps.windowInset * 2 == 8)
  }

  @Test func subtractsTheWindowInsetFromTheEdgePaddingSoTheEdgeGapIsExact() {
    let gaps = EngineConfigGaps(innerGap: 12, outerGap: 20)

    #expect(gaps.windowInset == 6)
    #expect(gaps.edgePadding + gaps.windowInset == 20)
  }

  @Test func neverWritesANegativeEdgePadding() {
    let gaps = EngineConfigGaps(innerGap: 40, outerGap: 4)

    #expect(gaps.edgePadding == 0)
  }

  @Test func leavesTheAnimationSpeedUnsetWhenAnimationIsOff() {
    let text = render { $0.animationSpeed = .off }

    #expect(!text.contains("animation_speed"))
  }

  @Test func mapsEachAnimationSpeed() {
    #expect(render { $0.animationSpeed = .fast }.contains("animation_speed = 20.0"))
    #expect(render { $0.animationSpeed = .standard }.contains("animation_speed = 14.0"))
    #expect(render { $0.animationSpeed = .relaxed }.contains("animation_speed = 8.0"))
  }

  @Test func centersOnlyWhenTheModeIsNotNever() {
    #expect(render { $0.layout.centerMode = .never }.contains("auto_center = false"))
    #expect(render { $0.layout.centerMode = .onOverflow }.contains("auto_center = true"))
    #expect(render { $0.layout.centerMode = .always }.contains("auto_center = true"))
  }

  @Test func scalesAndClampsTheSwipeSensitivity() {
    #expect(render { $0.swipeSensitivity = 1.0 }.contains("sensitivity = 0.35"))
    #expect(render { $0.swipeSensitivity = 0.5 }.contains("sensitivity = 0.175"))
    #expect(render { $0.swipeSensitivity = 2.0 }.contains("sensitivity = 0.7"))
    #expect(render { $0.swipeSensitivity = 10 }.contains("sensitivity = 2.0"))
    #expect(render { $0.swipeSensitivity = 0.01 }.contains("sensitivity = 0.1"))
  }

  @Test func omitsTheFingerCountWhenSwipingIsOff() {
    let text = render { $0.swipeGestureEnabled = false }

    #expect(!text.contains("fingers_count"))
    #expect(text.contains("direction = \"Natural\""))
  }

  @Test func switchesModifierScrollingOffWithAChordThatCannotBePressed() {
    #expect(render { $0.scrollGestureEnabled = true }.contains("modifier = \"ctrl + alt\""))
    #expect(render { $0.scrollGestureEnabled = false }.contains("modifier = \"alt + fn\""))
  }

  @Test func writesDimAsNegativeBrightnessAndZeroWhenOff() {
    #expect(
      render {
        $0.dimsInactiveWindows = true
        $0.dimAmount = 0.25
      }.contains("opacity = -0.25"))
    #expect(
      render {
        $0.dimsInactiveWindows = false
        $0.dimAmount = 0.25
      }.contains("[decorations.inactive.dim]\nopacity = 0.0"))
  }

  @Test func alwaysHidesTheEnginesOwnMenuBarItemAndPopup() {
    let text = render { _ in }

    #expect(text.contains("workspace_menu_status = false"))
    #expect(text.contains("workspace_popup_status = false"))
    #expect(text.contains("[decorations.menu.descriptor]\nstyle = \"hidden\""))
  }

  @Test func writesTheFocusSettingsExplicitly() {
    let defaults = render { _ in }
    let enabled = render {
      $0.focusFollowsMouse = true
      $0.mouseFollowsFocus = true
    }

    #expect(defaults.contains("focus_follows_mouse = false"))
    #expect(defaults.contains("mouse_follows_focus = false"))
    #expect(enabled.contains("focus_follows_mouse = true"))
    #expect(enabled.contains("mouse_follows_focus = true"))
  }

  @Test func turnsAppRulesIntoWindowRulesWithZeroBasedColumns() {
    let text = render {
      $0.appRules = [
        AppRule(bundleIdentifier: "com.example.Chat", behavior: .slot(1)),
        AppRule(bundleIdentifier: "com.example.Mail", behavior: .width(0.5)),
      ]
    }

    #expect(text.contains("bundle_id = \"com.example.Chat\"\ntitle = \".*\"\nindex = 0"))
    #expect(text.contains("bundle_id = \"com.example.Mail\"\ntitle = \".*\"\nwidth = 0.5"))
  }

  @Test func dropsTheDefaultWidthOnlyWhileAnAppRuleSetsAWidth() {
    let withRule = render {
      $0.appRules = [AppRule(bundleIdentifier: "com.example.Mail", behavior: .width(0.5))]
    }
    let without = render { $0.appRules = [] }

    #expect(!withRule.contains("[windows.all]\ntitle = \".*\"\nhorizontal_padding = 4\nvertical_padding = 4\nwidth"))
    #expect(without.contains("vertical_padding = 4\nwidth = 0.5"))
  }

  @Test func emitsNoBindingsWhileAShortcutIsBeingRecorded() {
    let config = EngineConfig(preferences: Preferences(), includesBindings: false)

    #expect(config.text.hasSuffix("[bindings]\n"))
    #expect(!config.text.contains("window_focus_west"))
  }

  @Test func escapesQuotesInBundleIdentifiers() {
    #expect(TomlString.quoted("a\"b\\c") == "\"a\\\"b\\\\c\"")
  }
}
