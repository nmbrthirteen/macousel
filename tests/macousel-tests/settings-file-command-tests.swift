import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct SettingsFileCommandTests {
  private final class OpenedURLs {
    var urls: [URL] = []
    var succeeds = true
  }

  private func command(
    _ suite: IsolatedDefaults, running: Bool = true, opened: OpenedURLs = OpenedURLs()
  ) -> SettingsFileCommand {
    SettingsFileCommand(
      defaults: suite.defaults, isAppRunning: { running },
      openURL: { url in
        opened.urls.append(url)
        return opened.succeeds
      })
  }

  private func write(_ text: String, named name: String, in directory: TemporaryDirectory) throws
    -> URL
  {
    let file = directory.url.appendingPathComponent(name)
    try Data(text.utf8).write(to: file)
    return file
  }

  @Test func exportWritesTheStoredPreferencesAndPrintsThePath() throws {
    let suite = try IsolatedDefaults()
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    PreferencesStore(defaults: suite.defaults).preferences.showsMinimap = false
    let file = directory.url.appendingPathComponent("out.json")

    let result = command(suite).run(arguments: ["export-settings", file.path])

    #expect(result?.status == 0)
    #expect(result?.stream == .standardOutput)
    #expect(result?.text.contains(file.path) == true)
    let loaded = try SettingsFile.decode(
      try Data(contentsOf: file), keepingOnboardingFrom: Preferences())
    #expect(loaded.showsMinimap == false)
  }

  @Test func exportToAMissingFolderFails() throws {
    let suite = try IsolatedDefaults()
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = directory.url.appendingPathComponent("absent/out.json")

    let result = command(suite).run(arguments: ["export-settings", file.path])

    #expect(result?.status == 1)
    #expect(result?.stream == .standardError)
    #expect(result?.text.hasPrefix("Could not write to \(file.path)") == true)
  }

  @Test func importStoresThePreferencesAndAsksTheRunningAppToReload() throws {
    let suite = try IsolatedDefaults()
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = try write(
      #"{"formatVersion": 1, "preferences": {"swipeFingers": 3}}"#, named: "in.json",
      in: directory)
    let opened = OpenedURLs()

    let result = command(suite, opened: opened).run(arguments: ["import-settings", file.path])

    #expect(result?.status == 0)
    #expect(opened.urls == [CommandURL.reloadSettings])
    #expect(PreferencesStore(defaults: suite.defaults).preferences.swipeFingers == 3)
  }

  @Test func importKeepsTheStoredOnboardingFlag() throws {
    let suite = try IsolatedDefaults()
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    PreferencesStore(defaults: suite.defaults).preferences.hasCompletedOnboarding = true
    let file = try write(#"{"preferences": {}}"#, named: "in.json", in: directory)

    _ = command(suite).run(arguments: ["import-settings", file.path])

    #expect(PreferencesStore(defaults: suite.defaults).preferences.hasCompletedOnboarding)
  }

  @Test func importWithoutARunningAppSucceedsAndOpensNothing() throws {
    let suite = try IsolatedDefaults()
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = try write(#"{"preferences": {"swipeFingers": 3}}"#, named: "in.json", in: directory)
    let opened = OpenedURLs()

    let result = command(suite, running: false, opened: opened)
      .run(arguments: ["import-settings", file.path])

    #expect(result?.status == 0)
    #expect(result?.text.contains("next time Macousel starts") == true)
    #expect(opened.urls.isEmpty)
    #expect(PreferencesStore(defaults: suite.defaults).preferences.swipeFingers == 3)
  }

  @Test func importOfAnInvalidFileFailsAndLeavesTheDefaultsAlone() throws {
    let suite = try IsolatedDefaults()
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = try write("{ nope", named: "bad.json", in: directory)
    let opened = OpenedURLs()

    let result = command(suite, opened: opened).run(arguments: ["import-settings", file.path])

    #expect(result?.status == 1)
    #expect(result?.stream == .standardError)
    #expect(opened.urls.isEmpty)
    #expect(suite.defaults.data(forKey: "preferences") == nil)
  }

  @Test func importOfAMissingFileFails() throws {
    let suite = try IsolatedDefaults()
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = directory.url.appendingPathComponent("absent.json")

    let result = command(suite).run(arguments: ["import-settings", file.path])

    #expect(result?.status == 1)
  }

  @Test func importFailsWhenTheRunningAppCannotBeReached() throws {
    let suite = try IsolatedDefaults()
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = try write(#"{"preferences": {"swipeFingers": 3}}"#, named: "in.json", in: directory)
    let opened = OpenedURLs()
    opened.succeeds = false

    let result = command(suite, opened: opened).run(arguments: ["import-settings", file.path])

    #expect(result?.status == 1)
    #expect(PreferencesStore(defaults: suite.defaults).preferences.swipeFingers == 3)
  }

  @Test func aMissingPathIsAUsageError() throws {
    let suite = try IsolatedDefaults()

    let exportResult = command(suite).run(arguments: ["export-settings"])
    let importResult = command(suite).run(arguments: ["import-settings", "a", "b"])

    #expect(exportResult?.status == 64)
    #expect(importResult?.status == 64)
    #expect(exportResult?.text == "Usage: Macousel export-settings <path>\n")
  }

  @Test func otherCommandsAreLeftToTheRestOfTheClient() throws {
    let suite = try IsolatedDefaults()

    #expect(command(suite).run(arguments: ["focus-left"]) == nil)
    #expect(command(suite).run(arguments: []) == nil)
  }
}
