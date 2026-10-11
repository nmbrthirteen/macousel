import Foundation

struct MissingFixtureScope: Error {}

@MainActor
final class FixtureRegistry {
  @TaskLocal static var current: FixtureRegistry?

  private var fixtures: [ControllerFixture] = []
  private var suites: [IsolatedDefaults] = []

  static func enroll(_ fixture: ControllerFixture) throws {
    guard let registry = current else { throw MissingFixtureScope() }
    registry.fixtures.append(fixture)
  }

  static func enroll(_ suite: IsolatedDefaults) throws {
    guard let registry = current else { throw MissingFixtureScope() }
    registry.suites.append(suite)
  }

  func tearDown() {
    fixtures.forEach { $0.tearDown() }
    suites.forEach { $0.remove() }
    fixtures = []
    suites = []
  }
}
