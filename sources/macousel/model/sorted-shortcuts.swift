import WindowSystem

struct SortedShortcuts: Encodable {
  let shortcuts: [Action: [Hotkey]]

  func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for (action, hotkeys) in shortcuts.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
      try container.encode(action)
      try container.encode(hotkeys)
    }
  }
}
