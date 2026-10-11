import WindowSystem

enum ShortcutOwner: Equatable {
  case action(Action)
  case app(String)
}

extension Preferences {
  func owner(of hotkey: Hotkey) -> ShortcutOwner? {
    if let action = shortcuts.first(where: { $0.value.contains(hotkey) })?.key {
      return .action(action)
    }
    return appShortcuts.first { $0.hotkey == hotkey }.map { .app($0.bundleIdentifier) }
  }

  mutating func assign(_ hotkey: Hotkey, to owner: ShortcutOwner) {
    switch owner {
    case .action(let action):
      shortcuts[action, default: []].append(hotkey)
    case .app(let bundleIdentifier):
      if let index = appShortcuts.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) {
        appShortcuts[index].hotkey = hotkey
      } else {
        appShortcuts.append(AppShortcut(bundleIdentifier: bundleIdentifier, hotkey: hotkey))
      }
    }
  }
}
