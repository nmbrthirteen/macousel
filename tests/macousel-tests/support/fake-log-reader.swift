@testable import Macousel

@MainActor
struct FakeLogReader: LogReading {
  var result: Result<String, any Error>

  func recentEntries() async throws -> String {
    try result.get()
  }
}
