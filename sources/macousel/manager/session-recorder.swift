import CoreGraphics
import StripCore

final class SessionRecorder {
  private static let saveDelay = Duration.seconds(2)

  private let state: TilingState
  private let source: any WindowSource
  private let store: PreferencesStore
  private let sessions: SessionStore
  private var titles: [CGWindowID: String] = [:]
  private var saved: [String: [SavedColumn]]
  private var pendingSave: Task<Void, Never>?

  init(
    state: TilingState, source: any WindowSource, store: PreferencesStore, sessions: SessionStore
  ) {
    self.state = state
    self.source = source
    self.store = store
    self.sessions = sessions
    saved = sessions.load()
  }

  var capturedTitles: [CGWindowID: String] { titles }

  func capture(_ windows: [any WindowHandle]) {
    windows.forEach { titles[$0.id] = $0.title }
  }

  func retain(only alive: Set<CGWindowID>) {
    titles = titles.filter { alive.contains($0.key) }
  }

  func takeSaved(forDisplay displayUUID: String) -> [SavedColumn]? {
    saved.removeValue(forKey: displayUUID)
  }

  func scheduleSave() {
    pendingSave?.cancel()
    pendingSave = Task {
      try? await Task.sleep(for: Self.saveDelay)
      if !Task.isCancelled { save() }
    }
  }

  func save() {
    pendingSave?.cancel()
    guard store.preferences.restoresSession else { return }
    let stripsByDisplay = state.activeKeys.reduce(into: [String: Strip]()) { strips, key in
      strips[key.displayUUID] = state.workspaces[key]?.strip
    }
    sessions.save(stripsByDisplay, windows: source.windows, titles: titles)
  }
}
