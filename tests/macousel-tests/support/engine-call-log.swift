@MainActor
final class EngineCallLog {
  private(set) var entries: [String] = []

  func append(_ entry: String) {
    entries.append(entry)
  }

  func index(of entry: String) -> Int? {
    entries.firstIndex(of: entry)
  }
}
