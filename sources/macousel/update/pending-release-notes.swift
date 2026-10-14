import Foundation

struct PendingReleaseNotes {
  static let key = "pendingReleaseNotes"

  let defaults: UserDefaults

  func save(_ release: Release) {
    let notes = ReleaseNotes(version: release.version.description, text: release.notes)
    defaults.set(try? JSONEncoder().encode(notes), forKey: Self.key)
  }

  func take(for current: AppVersion?) -> ReleaseNotes? {
    guard let data = defaults.data(forKey: Self.key),
      let notes = try? JSONDecoder().decode(ReleaseNotes.self, from: data),
      let saved = AppVersion(notes.version), let current
    else { return nil }
    guard saved <= current else { return nil }
    defaults.removeObject(forKey: Self.key)
    return saved == current ? notes : nil
  }
}
