import Foundation
import os

@Observable
final class Updater {
  typealias Sleep = (Duration) async throws -> Void

  static let checkInterval: TimeInterval = 24 * 60 * 60
  static let launchDelay = Duration.seconds(30)
  static let lastCheckKey = "lastUpdateCheck"
  static let developmentBuildMessage =
    "This is a development build, so it cannot check for updates. Install a release from the releases page."
  static let unknownFailureMessage = "The update failed. Check your internet connection and try again."

  private static let logger = Logger(subsystem: "dev.macousel.app", category: "updates")

  private(set) var state = UpdateState.idle

  private let feed: any ReleaseFetching
  private let installer: any ReleaseInstalling
  private let currentVersion: AppVersion?
  private let store: PreferencesStore
  private let defaults: UserDefaults
  private let now: () -> Date
  private let sleep: Sleep
  @ObservationIgnored private var scheduledChecks: Task<Void, Never>?

  init(
    feed: any ReleaseFetching, installer: any ReleaseInstalling, currentVersion: AppVersion?,
    store: PreferencesStore, defaults: UserDefaults = .standard,
    now: @escaping () -> Date = { Date() },
    sleep: @escaping Sleep = { try await Task.sleep(for: $0) }
  ) {
    self.feed = feed
    self.installer = installer
    self.currentVersion = currentVersion
    self.store = store
    self.defaults = defaults
    self.now = now
    self.sleep = sleep
  }

  func check() async {
    await performCheck(isAutomatic: false)
  }

  func install() async {
    guard case .available(let release) = state else { return }
    state = .downloading
    do {
      let prepared = try await installer.prepare(release)
      state = .installing
      try installer.apply(prepared)
    } catch {
      Self.logger.error("Install failed: \(error.localizedDescription, privacy: .public)")
      state = .failed(message(for: error))
    }
  }

  func startAutomaticChecks() {
    guard scheduledChecks == nil else { return }
    scheduledChecks = Task { await runAutomaticChecks() }
  }

  func runAutomaticChecks() async {
    do {
      try await sleep(Self.launchDelay)
      while true {
        await checkIfDue()
        try await sleep(.seconds(Self.checkInterval))
      }
    } catch {
      return
    }
  }

  private func checkIfDue() async {
    guard store.preferences.checksForUpdates, isDue else { return }
    await performCheck(isAutomatic: true)
  }

  private var isDue: Bool {
    guard let last = defaults.object(forKey: Self.lastCheckKey) as? Date else { return true }
    return now().timeIntervalSince(last) >= Self.checkInterval
  }

  private func performCheck(isAutomatic: Bool) async {
    guard !state.isBusy else { return }
    guard let currentVersion else {
      if !isAutomatic { state = .failed(Self.developmentBuildMessage) }
      return
    }
    let previous = state
    state = .checking
    do {
      let release = try await feed.latestRelease()
      defaults.set(now(), forKey: Self.lastCheckKey)
      state = release.version > currentVersion ? .available(release) : .upToDate
      Self.logger.info("Latest release is \(release.version.description, privacy: .public)")
    } catch {
      Self.logger.error("Check failed: \(error.localizedDescription, privacy: .public)")
      state = isAutomatic ? previous : .failed(message(for: error))
    }
  }

  private func message(for error: Error) -> String {
    (error as? any UserFacingError)?.message ?? Self.unknownFailureMessage
  }
}
