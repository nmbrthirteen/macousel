import Testing

@testable import Macousel

@MainActor
struct EngineSupportTests {
  private static let builtInOnly: [Action] = [.sendToScratchpad, .toggleScratchpad]

  @Test func everyActionIsMappedHandledOrBuiltInOnly() {
    for action in Action.allCases {
      switch action.paneruSupport {
      case .command(let command): #expect(!command.words.isEmpty, "\(action)")
      case .handledByMacousel:
        #expect(
          action == .togglePaused || action == .toggleOverview || action.paneruSequence != nil
            || Action.places.contains { action == .moveToColumn($0) })
      case .builtInOnly: #expect(Self.builtInOnly.contains(action), "\(action)")
      }
    }
  }

  @Test func exactlyTheDeclaredActionsAreBuiltInOnly() {
    let declared = Action.allCases.filter { $0.paneruSupport == .builtInOnly }

    #expect(Set(declared) == Set(Self.builtInOnly))
  }

  @Test func theBuiltInEngineSupportsEveryAction() {
    for action in Action.allCases { #expect(action.isSupported(by: .builtIn)) }
  }

  @Test func paneruSupportsEveryActionExceptTheBuiltInOnlyOnes() {
    for action in Action.allCases {
      #expect(action.isSupported(by: .paneru) == !Self.builtInOnly.contains(action))
    }
  }

  @Test func theEngineDirectionsMapToItsOwnStackCommands() {
    #expect(Action.stackLeft.paneruSupport == .command(PaneruCommand("window", "stack")))
    #expect(Action.popOutRight.paneruSupport == .command(PaneruCommand("window", "unstack")))
  }

  @Test func theOtherDirectionsAddASwapAroundTheEngineCommand() {
    #expect(Action.stackRight.paneruSupport == .handledByMacousel)
    #expect(
      Action.stackRight.paneruSequence == [
        PaneruCommand("window", "swap", "east"), PaneruCommand("window", "stack"),
      ])
    #expect(Action.popOutLeft.paneruSupport == .handledByMacousel)
    #expect(
      Action.popOutLeft.paneruSequence == [
        PaneruCommand("window", "unstack"), PaneruCommand("window", "swap", "west"),
      ])
    #expect(Action.stackLeft.paneruSequence == nil)
  }

  @Test func mapsTheLastColumnPlaceToFocusLast() {
    #expect(
      Action.focusColumn(8).paneruSupport == .command(PaneruCommand("window", "focus", "8")))
    #expect(
      Action.focusColumn(9).paneruSupport == .command(PaneruCommand("window", "focus", "last")))
  }

  @Test func bindingKeysJoinTheCommandWordsWithUnderscores() {
    #expect(PaneruCommand("window", "vertical", "grow").bindingKey == "window_vertical_grow")
  }

  @Test func featureTableDisablesBuiltInOnlyControlsUnderPaneru() {
    for feature in EngineFeature.allCases {
      #expect(feature.isSupported(by: .builtIn) == (feature != .nativeTabGrouping))
      #expect(
        feature.isSupported(by: .paneru) == (feature == .dragPreviews || feature == .nativeTabGrouping))
    }
    #expect(EngineFeature.unsupportedCaption == "Built-in engine only.")
    #expect(EngineFeature.nativeTabGrouping.unavailableCaption == "Paneru engine only.")
    #expect(EngineFeature.dragPreviews.unavailableCaption == "Built-in engine only.")
  }

  @Test func displayActionsMapToPaneruCommands() {
    #expect(Action.focusNextDisplay.paneruSupport == .command(PaneruCommand("mouse", "nextdisplay")))
    #expect(
      Action.sendToNextDisplayWithoutFollowing.paneruSupport
        == .command(PaneruCommand("window", "nextdisplaysend")))
  }

  @Test func shortcutRowsCarryTheUnavailableCaption() {
    #expect(ShortcutRow.unavailableCaption == "Not available with the Paneru engine")
  }
}
