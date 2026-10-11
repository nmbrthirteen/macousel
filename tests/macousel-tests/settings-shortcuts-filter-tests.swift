import Testing

@testable import Macousel

@MainActor
struct SettingsShortcutsFilterTests {
  private func titles(_ filter: ShortcutsFilter) -> [String] {
    filter.entries.flatMap { $0.actions.map(\.title) }
  }

  @Test func emptyQueryKeepsEveryAction() {
    let filter = ShortcutsFilter()
    #expect(filter.entries.flatMap(\.actions).count == Action.allCases.count)
    #expect(!filter.isFiltering)
  }

  @Test func whitespaceOnlyQueryKeepsEveryAction() {
    let filter = ShortcutsFilter(query: "   ")
    #expect(filter.entries.flatMap(\.actions).count == Action.allCases.count)
    #expect(!filter.isFiltering)
  }

  @Test func queryMatchesTitlesIgnoringCase() {
    let filter = ShortcutsFilter(query: "FOCUS left")
    #expect(titles(filter) == ["Focus left"])
    #expect(filter.isFiltering)
  }

  @Test func matchingActionsStayGroupedUnderTheirSections() {
    let filter = ShortcutsFilter(query: "overview")
    #expect(filter.entries.map(\.section) == [.overviewAndTiling])
    #expect(titles(filter) == ["Show or hide overview"])
  }

  @Test func sectionsWithoutMatchesAreDropped() {
    let filter = ShortcutsFilter(query: "column 3")
    #expect(filter.entries.map(\.section) == [.jumpToColumn, .moveToColumn])
  }

  @Test func unmatchedQueryLeavesNoEntries() {
    #expect(ShortcutsFilter(query: "zzzz").entries.isEmpty)
  }

  @Test func everyActionBelongsToExactlyOneSection() {
    let covered = ShortcutSection.allCases.flatMap(\.actions)
    #expect(covered.count == Action.allCases.count)
    #expect(Set(covered) == Set(Action.allCases))
  }

  @Test func sectionsFollowTheFocusAndMoveOrder() {
    #expect(
      ShortcutSection.allCases == [
        .focus, .jumpToColumn, .move, .moveToColumn, .size, .stacks, .overviewAndTiling,
      ])
  }
}
