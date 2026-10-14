import WindowSystem

extension Preferences {
  func primaryKeys(for action: Action) -> String? {
    shortcuts[action]?.first?.displayString
  }
}
