import Testing
import WindowSystem

@testable import Macousel

@MainActor
struct ShortcutMenuItemsTests {
  private func preferences(engine: WindowEngine, shortcuts: [Action: [Hotkey]]? = nil)
    -> Preferences
  {
    var preferences = Preferences()
    preferences.engine = engine
    preferences.shortcuts = shortcuts ?? Action.defaultShortcuts
    return preferences
  }

  private func actions(in sections: [ShortcutMenuSection]) -> [Action] {
    sections.flatMap { $0.items.map(\.action) }
  }

  @Test func builtInEngineShowsEveryAction() {
    let sections = ShortcutMenuItems.sections(in: preferences(engine: .builtIn))
    #expect(Set(actions(in: sections)) == Set(Action.allCases))
  }

  @Test func paneruHidesUnsupportedActions() {
    let sections = ShortcutMenuItems.sections(in: preferences(engine: .paneru))
    let shown = actions(in: sections)
    #expect(!shown.contains(.sendToScratchpad))
    #expect(!shown.contains(.moveToColumn(1)))
    #expect(shown.contains(.focusLeft))
  }

  @Test func keysListEveryHotkey() {
    let first = Hotkey(keyCode: 18, modifiers: [.control, .option])
    let second = Hotkey(keyCode: 19, modifiers: [.control, .command])
    let sections = ShortcutMenuItems.sections(
      in: preferences(engine: .builtIn, shortcuts: [.focusLeft: [first, second]]))
    let item = sections.flatMap(\.items).first { $0.action == .focusLeft }
    #expect(item?.keys == "\(first.displayString), \(second.displayString)")
  }

  @Test func emptyBindingsShowNotSet() {
    let sections = ShortcutMenuItems.sections(
      in: preferences(engine: .builtIn, shortcuts: [.focusLeft: []]))
    let items = sections.flatMap(\.items)
    #expect(items.first { $0.action == .focusLeft }?.keys == "Not set")
    #expect(items.first { $0.action == .focusRight }?.keys == "Not set")
  }

  @Test func sectionsWithoutVisibleActionsAreDropped() {
    let builtIn = ShortcutMenuItems.sections(in: preferences(engine: .builtIn))
    let paneru = ShortcutMenuItems.sections(in: preferences(engine: .paneru))
    #expect(builtIn.map(\.section).contains(.moveToColumn))
    #expect(!paneru.map(\.section).contains(.moveToColumn))
  }
}
