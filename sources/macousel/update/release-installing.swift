protocol ReleaseInstalling {
  func prepare(_ release: Release) async throws -> PreparedUpdate
  func apply(_ update: PreparedUpdate) throws
}
