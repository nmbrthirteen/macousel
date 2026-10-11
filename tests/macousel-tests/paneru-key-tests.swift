import Carbon.HIToolbox
import Testing
import WindowSystem

@testable import Macousel

@MainActor
struct PaneruKeyTests {
  private var defaultKeyCodes: Set<UInt16> {
    Set(Action.defaultShortcuts.values.flatMap { $0 }.map(\.keyCode))
  }

  @Test func everyKeyUsedByTheDefaultShortcutsHasAName() {
    for keyCode in defaultKeyCodes {
      #expect(PaneruKeyNames.name(for: keyCode) != nil, "key code \(keyCode)")
    }
  }

  @Test func namesLettersDigitsAndPunctuation() {
    #expect(PaneruKeyNames.name(for: UInt16(kVK_ANSI_H)) == "h")
    #expect(PaneruKeyNames.name(for: UInt16(kVK_ANSI_5)) == "5")
    #expect(PaneruKeyNames.name(for: UInt16(kVK_ANSI_Equal)) == "equal")
    #expect(PaneruKeyNames.name(for: UInt16(kVK_ANSI_LeftBracket)) == "leftbracket")
    #expect(PaneruKeyNames.name(for: UInt16(kVK_ANSI_RightBracket)) == "rightbracket")
    #expect(PaneruKeyNames.name(for: UInt16(kVK_LeftArrow)) == "leftarrow")
    #expect(PaneruKeyNames.name(for: UInt16(kVK_F12)) == "f12")
  }

  @Test func leavesKeysWithoutAPaneruNameUnmapped() {
    #expect(PaneruKeyNames.name(for: UInt16(kVK_ANSI_KeypadEnter)) == nil)
    #expect(PaneruKeyNames.name(for: UInt16(kVK_ForwardDelete)) == nil)
    #expect(PaneruKeyNames.name(for: 0xFF) == nil)
  }

  @Test func buildsChordsInTheEngineModifierOrder() {
    let every = Hotkey(
      keyCode: UInt16(kVK_ANSI_L), modifiers: [.control, .command, .shift, .option])
    let base = Hotkey(keyCode: UInt16(kVK_RightArrow), modifiers: [.control, .option])

    #expect(PaneruChord.text(for: every) == "alt + shift + cmd + ctrl - l")
    #expect(PaneruChord.text(for: base) == "alt + ctrl - rightarrow")
  }

  @Test func reportsAHotkeyWhoseKeyHasNoName() {
    let hotkey = Hotkey(keyCode: UInt16(kVK_ANSI_KeypadEnter), modifiers: [.control])

    #expect(PaneruChord.text(for: hotkey) == nil)
    #expect(!PaneruChord.isAvailable(hotkey))
  }

  @Test func leavesAnUnmappedShortcutOutOfTheFile() {
    var preferences = Preferences()
    preferences.shortcuts[.focusLeft] = [
      Hotkey(keyCode: UInt16(kVK_ANSI_KeypadEnter), modifiers: [.control])
    ]

    let text = EngineConfig(preferences: preferences).text

    #expect(!text.contains("window_focus_west"))
    #expect(text.contains("window_focus_east"))
  }
}
