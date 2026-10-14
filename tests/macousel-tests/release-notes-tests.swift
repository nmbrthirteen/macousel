import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct ReleaseNotesTests {
  private let suite: IsolatedDefaults

  init() throws {
    suite = try IsolatedDefaults()
  }

  private func save(version: String) throws {
    let notes = ReleaseNotes(version: version, text: "- Faster")
    suite.defaults.set(try JSONEncoder().encode(notes), forKey: PendingReleaseNotes.key)
  }

  @Test func readsParagraphsAndBulletsUntilTheChangelogLink() {
    let notes = ReleaseNotes(
      version: "0.3.0",
      text: """
        Two displays work.
        Better than before.

        - First change
        * Second change

        **Full Changelog**: https://example.com

        SHA-256 sums
        """)

    #expect(
      notes.blocks == [
        .paragraph("Two displays work. Better than before."),
        .bullet("First change"), .bullet("Second change"),
      ])
  }

  @Test func showsTheNotesOnceForTheInstalledVersion() throws {
    try save(version: "0.3.0")
    let pending = PendingReleaseNotes(defaults: suite.defaults)

    #expect(pending.take(for: AppVersion("0.3.0"))?.version == "0.3.0")
    #expect(pending.take(for: AppVersion("0.3.0")) == nil)
  }

  @Test func keepsNotesForAnUpdateThatHasNotInstalledYet() throws {
    try save(version: "0.3.0")
    let pending = PendingReleaseNotes(defaults: suite.defaults)

    #expect(pending.take(for: AppVersion("0.2.0")) == nil)
    #expect(pending.take(for: AppVersion("0.3.0")) != nil)
  }

  @Test func dropsNotesFromAnOlderVersion() throws {
    try save(version: "0.2.0")
    let pending = PendingReleaseNotes(defaults: suite.defaults)

    #expect(pending.take(for: AppVersion("0.3.0")) == nil)
    #expect(suite.defaults.data(forKey: PendingReleaseNotes.key) == nil)
  }
}
