import Testing

@testable import Macousel

@MainActor
struct EngineSupportTests {
  private static let builtInOnly: [Action] =
    Action.places.map { Action.moveToColumn($0) } + [.sendToScratchpad, .toggleScratchpad]

  @Test func everyActionIsMappedHandledOrBuiltInOnly() {
    for action in Action.allCases {
      switch action.paneruSupport {
      case .command(let command): #expect(!command.words.isEmpty, "\(action)")
      case .handledByMacousel: #expect(action == .togglePaused || action == .toggleOverview)
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

  @Test func mapsBothStackActionsAndBothPopOutActionsToOneCommand() {
    #expect(Action.stackLeft.paneruSupport == Action.stackRight.paneruSupport)
    #expect(Action.stackLeft.paneruSupport == .command(PaneruCommand("window", "stack")))
    #expect(Action.popOutLeft.paneruSupport == Action.popOutRight.paneruSupport)
    #expect(Action.popOutLeft.paneruSupport == .command(PaneruCommand("window", "unstack")))
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
      #expect(feature.isSupported(by: .builtIn))
      #expect(!feature.isSupported(by: .paneru))
    }
    #expect(EngineFeature.unsupportedCaption == "Built-in engine only.")
  }

  @Test func shortcutRowsCarryTheUnavailableCaption() {
    #expect(ShortcutRow.unavailableCaption == "Not available with the Paneru engine")
  }
}
