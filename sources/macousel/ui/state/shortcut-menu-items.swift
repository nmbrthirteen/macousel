import WindowSystem

struct ShortcutMenuItem: Equatable, Identifiable {
  static let unsetKeys = "Not set"

  let action: Action
  let title: String
  let keys: String

  var id: Action { action }
}

struct ShortcutMenuSection: Equatable, Identifiable {
  let section: ShortcutSection
  let items: [ShortcutMenuItem]

  var id: ShortcutSection { section }
  var title: String { section.title }
}

enum ShortcutMenuItems {
  static func sections(in preferences: Preferences) -> [ShortcutMenuSection] {
    ShortcutSection.allCases.compactMap { section in
      let items = section.actions
        .filter { $0.isSupported(by: preferences.engine) }
        .map { item(for: $0, in: preferences) }
      return items.isEmpty ? nil : ShortcutMenuSection(section: section, items: items)
    }
  }

  private static func item(for action: Action, in preferences: Preferences) -> ShortcutMenuItem {
    let hotkeys = preferences.shortcuts[action] ?? []
    let keys =
      hotkeys.isEmpty
      ? ShortcutMenuItem.unsetKeys : hotkeys.map(\.displayString).joined(separator: ", ")
    return ShortcutMenuItem(action: action, title: action.title, keys: keys)
  }
}
