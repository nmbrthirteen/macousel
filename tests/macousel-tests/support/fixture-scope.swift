import Testing

struct FixtureScope: SuiteTrait, TestTrait, TestScoping {
  var isRecursive: Bool { true }

  func provideScope(
    for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void
  ) async throws {
    guard testCase != nil else {
      try await function()
      return
    }
    let registry = await MainActor.run { FixtureRegistry() }
    do {
      try await FixtureRegistry.$current.withValue(registry, operation: function)
    } catch {
      await registry.tearDown()
      throw error
    }
    await registry.tearDown()
  }
}

extension Trait where Self == FixtureScope {
  static var fixtureScope: FixtureScope { FixtureScope() }
}
