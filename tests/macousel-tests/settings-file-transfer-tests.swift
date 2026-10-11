import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct SettingsFileTransferTests {
  private func store() throws -> PreferencesStore {
    PreferencesStore(defaults: try IsolatedDefaults().defaults)
  }

  private func transfer(
    _ store: PreferencesStore, exporting: URL? = nil, importing: URL? = nil
  ) -> SettingsFileTransfer {
    SettingsFileTransfer(
      store: store,
      panels: SettingsFilePanels(exportDestination: { exporting }, importSource: { importing }))
  }

  @Test func anExportedFileImportsIntoAnotherStore() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = directory.url.appendingPathComponent("settings.json")
    let source = try store()
    source.preferences.showsMinimap = false
    source.preferences.layout.defaultWidth = 0.4
    let target = try store()
    target.preferences.hasCompletedOnboarding = true

    let exporter = transfer(source, exporting: file)
    exporter.exportSettings()
    let importer = transfer(target, importing: file)
    importer.importSettings()

    var expected = source.preferences
    expected.hasCompletedOnboarding = true
    #expect(exporter.errorMessage == nil)
    #expect(importer.errorMessage == nil)
    #expect(target.preferences == expected)
  }

  @Test func aFailedImportShowsTheErrorAndChangesNothing() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = directory.url.appendingPathComponent("broken.json")
    try Data("{ nope".utf8).write(to: file)
    let store = try store()
    store.preferences.swipeFingers = 3
    let before = store.preferences
    var changes = 0
    store.onChange = { changes += 1 }

    let importer = transfer(store, importing: file)
    importer.importSettings()

    #expect(importer.errorMessage?.contains("not valid JSON") == true)
    #expect(store.preferences == before)
    #expect(changes == 0)
  }

  @Test func aMissingFileShowsAnErrorAndChangesNothing() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let store = try store()
    let before = store.preferences

    let importer = transfer(store, importing: directory.url.appendingPathComponent("absent.json"))
    importer.importSettings()

    #expect(importer.errorMessage != nil)
    #expect(store.preferences == before)
  }

  @Test func aSuccessfulImportAppliesThroughTheChangeCallback() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = directory.url.appendingPathComponent("settings.json")
    try Data(#"{"preferences": {"showsMinimap": false}}"#.utf8).write(to: file)
    let store = try store()
    var changes = 0
    store.onChange = { changes += 1 }

    transfer(store, importing: file).importSettings()

    #expect(store.preferences.showsMinimap == false)
    #expect(changes == 1)
  }

  @Test func anExportToAMissingFolderShowsAnError() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = directory.url.appendingPathComponent("absent/settings.json")

    let exporter = transfer(try store(), exporting: file)
    exporter.exportSettings()

    #expect(exporter.errorMessage?.hasPrefix("Could not export settings") == true)
  }

  @Test func cancellingThePanelsDoesNothing() throws {
    let store = try store()

    let idle = transfer(store)
    idle.exportSettings()
    idle.importSettings()

    #expect(idle.errorMessage == nil)
    #expect(idle.statusMessage == nil)
  }
}
