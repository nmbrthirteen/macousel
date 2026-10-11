struct SystemLogReader: LogReading {
  struct Failure: Error {
    let status: Int32
    let output: String
  }

  static let subsystem = "dev.macousel.app"
  static let window = "15m"

  func recentEntries() async throws -> String {
    let output = try await ProcessRunner.capture(
      "/usr/bin/log",
      [
        "show", "--last", Self.window, "--info", "--style", "compact",
        "--predicate", "subsystem == \"\(Self.subsystem)\"",
      ])
    guard output.status == 0 else {
      throw Failure(status: output.status, output: output.text)
    }
    return output.text
  }
}
