import Foundation
import OSLog

struct RecordedLog {
  private let started = Date().addingTimeInterval(-1)

  @concurrent
  func messages(category: String) async throws -> [String] {
    let store = try OSLogStore(scope: .currentProcessIdentifier)
    let predicate = NSPredicate(
      format: "subsystem == %@ AND category == %@", "dev.macousel.app", category)
    return try store.getEntries(at: store.position(date: started), matching: predicate)
      .compactMap { ($0 as? OSLogEntryLog)?.composedMessage }
  }
}
