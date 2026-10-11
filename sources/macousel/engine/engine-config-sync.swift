import Foundation

final class EngineConfigSync {
  private let store: PreferencesStore
  private let writer: EngineConfigWriter
  private let url: URL
  private(set) var lastWritten: String?

  init(store: PreferencesStore, writer: EngineConfigWriter, url: URL) {
    self.store = store
    self.writer = writer
    self.url = url
  }

  var currentText: String {
    EngineConfig(preferences: store.preferences, includesBindings: !store.isRecordingShortcut).text
  }

  func writeCurrent() throws {
    let text = currentText
    try writer.write(text, to: url)
    lastWritten = text
  }

  func writeIfChanged() throws {
    guard currentText != lastWritten else { return }
    try writeCurrent()
  }

  func forget() {
    lastWritten = nil
  }
}
