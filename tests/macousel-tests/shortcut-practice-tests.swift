import Testing
import WindowSystem

@testable import Macousel

@MainActor
struct ShortcutPracticeTests {
  private let shortcuts = Action.defaultShortcuts

  private func hotkey(_ action: Action, at index: Int = 0) -> Hotkey {
    shortcuts[action]![index]
  }

  @Test func aBoundHotkeyTicksItsAction() {
    let practice = ShortcutPractice()
    practice.record(hotkey(.cycleWidth), shortcuts: shortcuts)
    #expect(practice.isPracticed(.cycleWidth))
    #expect(!practice.isPracticed(.focusLeft))
  }

  @Test func anUnboundHotkeyTicksNothing() {
    let practice = ShortcutPractice()
    practice.record(Hotkey(keyCode: 0, modifiers: [.command]), shortcuts: shortcuts)
    #expect(practice.practiced.isEmpty)
  }

  @Test func aColumnJumpHotkeyTicksTheJumpRow() {
    let practice = ShortcutPractice()
    practice.record(hotkey(.focusColumn(5)), shortcuts: shortcuts)
    #expect(practice.isPracticed(ShortcutPractice.columnJump))
  }

  @Test func aNonStarterActionTicksNothing() {
    let practice = ShortcutPractice()
    practice.record(hotkey(.focusUp), shortcuts: shortcuts)
    #expect(practice.practiced.isEmpty)
  }

  @Test func aCustomBindingIsHonored() {
    var custom = shortcuts
    let replacement = Hotkey(keyCode: 12, modifiers: [.control, .command])
    custom[.toggleOverview] = [replacement]
    let practice = ShortcutPractice()
    practice.record(hotkey(.toggleOverview), shortcuts: custom)
    #expect(practice.practiced.isEmpty)
    practice.record(replacement, shortcuts: custom)
    #expect(practice.isPracticed(.toggleOverview))
  }

  @Test func alternateBindingsBothTick() {
    let count = shortcuts[.focusLeft]?.count ?? 0
    #expect(count > 1)
    for index in 0..<count {
      let practice = ShortcutPractice()
      practice.record(hotkey(.focusLeft, at: index), shortcuts: shortcuts)
      #expect(practice.isPracticed(.focusLeft))
    }
  }
}
