import Foundation
import Testing
import WindowSystem

@testable import Macousel

@MainActor
struct ActionRawValueTests {
  nonisolated private static let legacyNames = [
    "focusLeft", "focusRight", "focusUp", "focusDown", "focusFirst", "focusLast",
    "focusColumn1", "focusColumn2", "focusColumn3", "focusColumn4", "focusColumn5",
    "focusColumn6", "focusColumn7", "focusColumn8", "focusColumn9",
    "moveLeft", "moveRight", "moveUp", "moveDown", "sendToNextDisplay", "togglePaused",
    "cycleWidth", "toggleFullWidth", "center", "wider", "narrower", "taller", "shorter",
    "equalizeHeights", "stackLeft", "stackRight", "popOutLeft", "popOutRight", "toggleTabbed",
    "toggleFloating",
  ]

  @Test(arguments: Action.allCases)
  func rawValueRoundTrips(action: Action) {
    #expect(Action(rawValue: action.rawValue) == action)
  }

  @Test(arguments: Action.allCases)
  func codableRoundTrips(action: Action) throws {
    let data = try JSONEncoder().encode([action])
    #expect(try JSONDecoder().decode([Action].self, from: data) == [action])
    #expect(String(decoding: data, as: UTF8.self) == "[\"\(action.rawValue)\"]")
  }

  @Test(arguments: legacyNames)
  func savedNamesKeepDecoding(name: String) throws {
    let action = try #require(Action(rawValue: name))
    #expect(action.rawValue == name)
  }

  @Test func newNamesDecode() throws {
    #expect(Action(rawValue: "moveToColumn1") == .moveToColumn(1))
    #expect(Action(rawValue: "moveToColumn9") == .moveToColumn(9))
    #expect(Action(rawValue: "moveToFirst") == .moveToFirst)
    #expect(Action(rawValue: "moveToLast") == .moveToLast)
    #expect(Action(rawValue: "focusColumn4") == .focusColumn(4))
  }

  @Test(arguments: ["focusColumn0", "focusColumn10", "moveToColumn0", "moveToColumn10", "nope"])
  func unknownNamesAreRejected(name: String) {
    #expect(Action(rawValue: name) == nil)
  }

  @Test func allCasesAreUniqueAndCountEveryPlace() {
    #expect(Set(Action.allCases).count == Action.allCases.count)
    #expect(Set(Action.allCases.map(\.rawValue)).count == Action.allCases.count)
    #expect(Action.allCases.filter { $0.rawValue.hasPrefix("focusColumn") }.count == 9)
    #expect(Action.allCases.filter { $0.rawValue.hasPrefix("moveToColumn") }.count == 9)
  }

  @Test func commandAndTitleNamesComeFromThePlace() {
    #expect(Action.moveToColumn(2).commandName == "move-to-column-2")
    #expect(Action.moveToColumn(2).title == "Move to column 2")
    #expect(Action.moveToColumn(9).title == "Move to column 9 (last)")
    #expect(Action.moveToFirst.commandName == "move-to-first")
    #expect(Action.moveToLast.commandName == "move-to-last")
  }

  @Test func numberedActionsAreNavigation() {
    #expect(Action.focusColumn(5).group == .navigate)
    #expect(Action.moveToColumn(5).group == .navigate)
    #expect(Action.moveToFirst.group == .navigate)
  }

  @Test func oldSavedPreferencesWithFocusColumnShortcutsStillDecode() throws {
    let json = """
      {"shortcuts":["focusColumn3",[{"keyCode":0,"modifiers":4}],"focusLeft",[]]}
      """
    let decoded = try JSONDecoder().decode(Preferences.self, from: Data(json.utf8))
    #expect(decoded.shortcuts[.focusColumn(3)] == [Hotkey(keyCode: 0, modifiers: .shift)])
    #expect(decoded.shortcuts[.focusLeft] == [])
  }
}
