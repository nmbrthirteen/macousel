import Foundation
import WindowSystem
import os

struct PendingReleaseNotes {
  static let key = "pendingReleaseNotes"
  private static let logger = Logger(subsystem: Log.subsystem, category: "updates")

  let defaults: UserDefaults

  func save(_ release: Release) {
    let notes = ReleaseNotes(version: release.version.description, text: release.notes)
    do {
      defaults.set(try JSONEncoder().encode(notes), forKey: Self.key)
    } catch {
      Self.logger.error("Could not save the release notes: \(error, privacy: .public)")
    }
  }

  func take(for current: AppVersion?) -> ReleaseNotes? {
    guard let data = defaults.data(forKey: Self.key) else { return nil }
    let notes: ReleaseNotes
    do {
      notes = try JSONDecoder().decode(ReleaseNotes.self, from: data)
    } catch {
      Self.logger.error("Dropped unreadable release notes: \(error, privacy: .public)")
      defaults.removeObject(forKey: Self.key)
      return nil
    }
    guard let saved = AppVersion(notes.version), let current else { return nil }
    guard saved <= current else { return nil }
    defaults.removeObject(forKey: Self.key)
    return saved == current ? notes : nil
  }
}
