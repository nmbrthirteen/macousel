import Foundation

struct ShortcutsFilter: Equatable {
  struct Entry: Equatable, Identifiable {
    let section: ShortcutSection
    let actions: [Action]

    var id: ShortcutSection { section }
  }

  var query = ""

  var isFiltering: Bool { !needle.isEmpty }

  var entries: [Entry] {
    ShortcutSection.allCases.compactMap { section in
      let found = section.actions.filter { isMatch($0) }
      return found.isEmpty ? nil : Entry(section: section, actions: found)
    }
  }

  private var needle: String {
    query.trimmingCharacters(in: .whitespaces)
  }

  private func isMatch(_ action: Action) -> Bool {
    needle.isEmpty || action.title.localizedCaseInsensitiveContains(needle)
  }
}
