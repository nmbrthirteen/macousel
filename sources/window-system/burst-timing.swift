import Foundation

nonisolated struct BurstTiming: Sendable {
  static let timeoutMilliseconds = 240.0

  private(set) var count = 0
  private(set) var timedOutCount = 0
  private(set) var totalMilliseconds = 0.0
  private(set) var maximumMilliseconds = 0.0

  var averageMilliseconds: Double {
    count == 0 ? 0 : totalMilliseconds / Double(count)
  }

  mutating func record(milliseconds: Double) {
    count += 1
    if milliseconds >= Self.timeoutMilliseconds { timedOutCount += 1 }
    totalMilliseconds += milliseconds
    maximumMilliseconds = max(maximumMilliseconds, milliseconds)
  }
}
