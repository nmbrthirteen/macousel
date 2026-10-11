import WindowSystem

struct EngineConfigBindings {
  let shortcuts: [Action: [Hotkey]]

  var lines: [String] {
    var chordsByCommand: [String: [String]] = [:]
    for action in Action.allCases {
      guard case .command(let command) = action.paneruSupport else { continue }
      for hotkey in shortcuts[action] ?? [] {
        guard let chord = PaneruChord.text(for: hotkey) else { continue }
        if chordsByCommand[command.bindingKey]?.contains(chord) != true {
          chordsByCommand[command.bindingKey, default: []].append(chord)
        }
      }
    }
    let entries = chordsByCommand.keys.sorted().map { key -> String in
      let chords = (chordsByCommand[key] ?? []).map { TomlString.quoted($0) }
      return chords.count == 1 ? "\(key) = \(chords[0])" : "\(key) = [\(chords.joined(separator: ", "))]"
    }
    return ["[bindings]"] + entries
  }
}
