import Foundation

@MainActor
final class ScriptedSleep {
  private let allowedCalls: Int
  private(set) var durations: [Duration] = []
  private(set) var now: Date

  init(allowedCalls: Int, start: Date) {
    self.allowedCalls = allowedCalls
    now = start
  }

  func sleep(_ duration: Duration) async throws {
    durations.append(duration)
    if durations.count > allowedCalls { throw CancellationError() }
    now.addTimeInterval(TimeInterval(duration.components.seconds))
  }
}
