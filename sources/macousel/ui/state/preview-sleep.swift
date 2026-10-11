typealias PreviewSleep = (Duration) async throws -> Void

enum PreviewClock {
  static let live: PreviewSleep = { duration in
    try await Task.sleep(for: duration)
  }
}
