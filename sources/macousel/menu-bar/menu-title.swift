import Foundation

// Menu items use title-style capitalization, while action and section titles are written in
// sentence case for the Settings window. "Up" and "out" stay capitalized because every title
// here uses them as verb particles, as in "Move Up" and "Pop Out".
nonisolated enum MenuTitle {
  private static let minorWords: Set<String> = [
    "a", "an", "the", "and", "but", "or", "nor", "for", "so", "yet", "as", "at", "by", "in",
    "of", "on", "per", "to", "via", "with", "from", "into", "onto",
  ]

  static func titleCased(_ title: String) -> String {
    let words = title.split(separator: " ", omittingEmptySubsequences: false)
    return words.indices.map { index in
      let word = words[index]
      let bare = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
      let isEdge = index == words.startIndex || index == words.index(before: words.endIndex)
      return isEdge || !minorWords.contains(bare) ? capitalizingFirstLetter(word) : String(word)
    }
    .joined(separator: " ")
  }

  private static func capitalizingFirstLetter(_ word: Substring) -> String {
    guard let index = word.firstIndex(where: \.isLetter) else { return String(word) }
    return String(word[..<index]) + word[index].uppercased() + word[word.index(after: index)...]
  }
}
