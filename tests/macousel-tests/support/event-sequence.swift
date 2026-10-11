import CoreGraphics

@MainActor
final class EventSequence {
  enum Entry: Equatable {
    case frameSubmitted(CGWindowID)
    case focused(CGWindowID)
  }

  private(set) var entries: [Entry] = []

  func record(_ entry: Entry) {
    entries.append(entry)
  }

  func entries(since mark: Int) -> [Entry] {
    Array(entries[mark...])
  }

  var mark: Int { entries.count }
}
