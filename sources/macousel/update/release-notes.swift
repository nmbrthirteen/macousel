nonisolated struct ReleaseNotes: Equatable, Codable, Sendable {
  enum Block: Equatable, Sendable {
    case paragraph(String)
    case bullet(String)
  }

  private static let endMarkers = ["**Full Changelog**", "SHA-256 sums"]
  private static let bulletPrefixes = ["- ", "* "]

  let version: String
  let text: String

  var blocks: [Block] {
    var blocks: [Block] = []
    var paragraph: [String] = []

    func closeParagraph() {
      if !paragraph.isEmpty { blocks.append(.paragraph(paragraph.joined(separator: " "))) }
      paragraph = []
    }

    for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
      let line = raw.trimmingCharacters(in: .whitespaces)
      if Self.endMarkers.contains(where: line.hasPrefix) { break }
      if let prefix = Self.bulletPrefixes.first(where: line.hasPrefix) {
        closeParagraph()
        blocks.append(.bullet(String(line.dropFirst(prefix.count))))
      } else if line.isEmpty || line.hasPrefix("#") {
        closeParagraph()
      } else {
        paragraph.append(line)
      }
    }
    closeParagraph()
    return blocks
  }
}
