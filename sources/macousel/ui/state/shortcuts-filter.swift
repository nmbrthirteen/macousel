import Foundation

struct ShortcutsFilter: Equatable {
  struct Entry: Equatable, Identifiable {
    let group: Action.Group
    let actions: [Action]

    var id: Action.Group { group }
  }

  var query = ""

  var isFiltering: Bool { !needle.isEmpty }

  var entries: [Entry] {
    Action.Group.allCases.compactMap { group in
      let found = group.actions.filter { isMatch($0) }
      return found.isEmpty ? nil : Entry(group: group, actions: found)
    }
  }

  private var needle: String {
    query.trimmingCharacters(in: .whitespaces)
  }

  private func isMatch(_ action: Action) -> Bool {
    needle.isEmpty || action.title.localizedCaseInsensitiveContains(needle)
  }
}
