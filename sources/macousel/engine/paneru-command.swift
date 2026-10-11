nonisolated struct PaneruCommand: Hashable, Sendable {
  let words: [String]

  init(_ words: String...) {
    self.words = words
  }

  var bindingKey: String { words.joined(separator: "_") }
}
