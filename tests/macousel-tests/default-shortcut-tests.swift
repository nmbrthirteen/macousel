import Carbon.HIToolbox
import Testing
import WindowSystem

@testable import Macousel

@MainActor
struct DefaultShortcutTests {
  private static let digitKeys = [
    kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5,
    kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9,
  ]

  @Test func focusPlacesUseControlOptionAndTheDigit() {
    for (place, key) in zip(Action.places, Self.digitKeys) {
      let expected = Hotkey(keyCode: UInt16(key), modifiers: [.control, .option])
      #expect(Action.defaultShortcuts[.focusColumn(place)] == [expected])
    }
  }

  @Test func movePlacesUseControlOptionShiftAndTheDigit() {
    for (place, key) in zip(Action.places, Self.digitKeys) {
      let expected = Hotkey(keyCode: UInt16(key), modifiers: [.control, .option, .shift])
      #expect(Action.defaultShortcuts[.moveToColumn(place)] == [expected])
    }
  }

  @Test func moveToFirstAndLastUseEveryModifierWithTheArrows() {
    let every: Hotkey.Modifiers = [.control, .option, .command, .shift]
    #expect(
      Action.defaultShortcuts[.moveToFirst]
        == [Hotkey(keyCode: UInt16(kVK_LeftArrow), modifiers: every)])
    #expect(
      Action.defaultShortcuts[.moveToLast]
        == [Hotkey(keyCode: UInt16(kVK_RightArrow), modifiers: every)])
  }

  @Test func overviewAndScratchpadUseControlOptionWithOAndS() {
    let base: Hotkey.Modifiers = [.control, .option]
    #expect(
      Action.defaultShortcuts[.toggleOverview]
        == [Hotkey(keyCode: UInt16(kVK_ANSI_O), modifiers: base)])
    #expect(
      Action.defaultShortcuts[.toggleScratchpad]
        == [Hotkey(keyCode: UInt16(kVK_ANSI_S), modifiers: base)])
    #expect(
      Action.defaultShortcuts[.sendToScratchpad]
        == [Hotkey(keyCode: UInt16(kVK_ANSI_S), modifiers: base.union(.shift))])
  }

  @Test func pinningUsesControlOptionPAndControlOptionShiftP() {
    let base: Hotkey.Modifiers = [.control, .option]
    #expect(
      Action.defaultShortcuts[.pinWindow]
        == [Hotkey(keyCode: UInt16(kVK_ANSI_P), modifiers: base)])
    #expect(
      Action.defaultShortcuts[.togglePinnedWindows]
        == [Hotkey(keyCode: UInt16(kVK_ANSI_P), modifiers: base.union(.shift))])
  }

  @Test func displayActionsUseControlOptionDAndControlOptionShiftN() {
    let base: Hotkey.Modifiers = [.control, .option]
    #expect(
      Action.defaultShortcuts[.focusNextDisplay]
        == [Hotkey(keyCode: UInt16(kVK_ANSI_D), modifiers: base)])
    #expect(
      Action.defaultShortcuts[.sendToNextDisplayWithoutFollowing]
        == [Hotkey(keyCode: UInt16(kVK_ANSI_N), modifiers: base.union(.shift))])
  }

  @Test func keycapsSplitTheModifiersFromTheKey() {
    let hotkey = Hotkey(keyCode: UInt16(kVK_LeftArrow), modifiers: [.control, .option, .shift])
    #expect(hotkey.keycaps == ["⌃", "⌥", "⇧", "←"])
    #expect(hotkey.keycaps.joined() == hotkey.displayString)
  }

  @Test func everyActionButBringingBackHasADefaultAndNoTwoActionsShareOne() {
    let keys = Action.allCases.flatMap { Action.defaultShortcuts[$0] ?? [] }
    let bound = Action.allCases.filter { $0 != .bringBackFloatingWindows }
    #expect(bound.allSatisfy { Action.defaultShortcuts[$0]?.isEmpty == false })
    #expect(Set(keys).count == keys.count)
  }

  @Test func floatingLayerAndPreviousWindowUseControlOption() {
    let base: Hotkey.Modifiers = [.control, .option]
    #expect(
      Action.defaultShortcuts[.switchToFloatingWindows]
        == [Hotkey(keyCode: UInt16(kVK_ANSI_Grave), modifiers: base)])
    #expect(
      Action.defaultShortcuts[.focusPrevious]
        == [Hotkey(keyCode: UInt16(kVK_ANSI_Backslash), modifiers: base)])
  }

  @Test func newDefaultsStayUniqueUnderEveryShortcutBase() {
    for base in ShortcutBase.allCases {
      let keys = Action.defaultShortcuts(base: base).values.flatMap { $0 }
      #expect(Set(keys).count == keys.count, "\(base)")
    }
  }
}
