protocol ReleaseFetching {
  func latestRelease() async throws -> Release
}
