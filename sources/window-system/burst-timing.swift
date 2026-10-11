import Foundation

nonisolated struct BurstTiming: Sendable {
  private static let millisecondsPerSecond = 1_000.0
  private static let attosecondsPerMillisecond = 1e15

  private(set) var count = 0
  private(set) var totalMilliseconds = 0.0
  private(set) var maximumMilliseconds = 0.0

  var averageMilliseconds: Double {
    count == 0 ? 0 : totalMilliseconds / Double(count)
  }

  mutating func record(_ duration: Duration) {
    let components = duration.components
    let milliseconds =
      Double(components.seconds) * Self.millisecondsPerSecond
      + Double(components.attoseconds) / Self.attosecondsPerMillisecond
    count += 1
    totalMilliseconds += milliseconds
    maximumMilliseconds = max(maximumMilliseconds, milliseconds)
  }
}
