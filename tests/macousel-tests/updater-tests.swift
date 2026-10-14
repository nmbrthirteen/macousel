import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct UpdaterTests {
  private let launch = Date(timeIntervalSince1970: 1_000_000)
  private let suite: IsolatedDefaults
  private let store: PreferencesStore
  private let feed: FakeReleaseFeed
  private let installer = FakeReleaseInstaller()
  private let latest: Release

  init() throws {
    suite = try IsolatedDefaults()
    store = PreferencesStore(defaults: suite.defaults)
    latest = try ReleaseJSON.release(version: "0.2.0")
    feed = FakeReleaseFeed(result: .success(latest))
  }

  private func clock(allowedSleeps: Int = 1, startingAt start: Date? = nil) -> ScriptedSleep {
    ScriptedSleep(allowedCalls: allowedSleeps, start: start ?? launch)
  }

  private func updater(current: String? = "0.1.0", clock: ScriptedSleep? = nil) -> Updater {
    let clock = clock ?? self.clock()
    return Updater(
      feed: feed, installer: installer, currentVersion: current.flatMap { AppVersion($0) },
      store: store, defaults: suite.defaults, now: { clock.now },
      sleep: { duration in try await clock.sleep(duration) })
  }

  @Test func startsIdle() {
    #expect(updater().state == .idle)
  }

  @Test func reportsUpToDateWhenTheLatestReleaseMatchesTheRunningVersion() async throws {
    feed.result = .success(try ReleaseJSON.release(version: "0.1.0"))
    let updater = updater()

    await updater.check()

    #expect(updater.state == .upToDate)
  }

  @Test func offersAReleaseNewerThanTheRunningVersion() async {
    let updater = updater()

    await updater.check()

    #expect(updater.state == .available(latest))
  }

  @Test func showsTheFeedErrorMessageWhenTheCheckFails() async {
    feed.result = .failure(.rateLimited)
    let updater = updater()

    await updater.check()

    #expect(updater.state == .failed(UpdateFeedError.rateLimited.message))
  }

  @Test func aDevelopmentBuildCannotCheck() async {
    let updater = updater(current: nil)

    await updater.check()

    #expect(updater.state == .failed(Updater.developmentBuildMessage))
    #expect(feed.fetchCount == 0)
  }

  @Test func installPreparesAppliesAndEndsInstalling() async {
    let updater = updater()
    await updater.check()

    await updater.install()

    #expect(updater.state == .installing)
    #expect(installer.preparedReleases == [latest])
    #expect(installer.appliedUpdates.count == 1)
  }

  @Test func installKeepsTheReleaseNotesForTheNextLaunch() async {
    let updater = updater()
    await updater.check()

    await updater.install()

    let pending = PendingReleaseNotes(defaults: suite.defaults)
    #expect(pending.take(for: AppVersion("0.2.0"))?.text == latest.notes)
  }

  @Test func installFailureShowsTheInstallerMessage() async {
    installer.prepareError = .invalidSignature
    let updater = updater()
    await updater.check()

    await updater.install()

    #expect(updater.state == .failed(UpdateInstallError.invalidSignature.message))
    #expect(installer.appliedUpdates.isEmpty)
  }

  @Test func swapFailureShowsTheInstallerMessage() async {
    installer.applyError = .needsApplicationsFolder
    let updater = updater()
    await updater.check()

    await updater.install()

    #expect(updater.state == .failed("Move Macousel to the Applications folder, then update."))
  }

  @Test func installDoesNothingWithoutAnAvailableRelease() async {
    let updater = updater()

    await updater.install()

    #expect(updater.state == .idle)
    #expect(installer.preparedReleases.isEmpty)
  }

  @Test func theAutomaticCheckRunsAfterTheLaunchDelayAndRecordsTheDate() async {
    let clock = clock(allowedSleeps: 1)
    let updater = updater(clock: clock)

    await updater.runAutomaticChecks()

    #expect(feed.fetchCount == 1)
    #expect(updater.state == .available(latest))
    #expect(suite.defaults.object(forKey: Updater.lastCheckKey) as? Date == launch.addingTimeInterval(30))
    #expect(clock.durations == [Updater.launchDelay, .seconds(Updater.checkInterval)])
  }

  @Test func theAutomaticCheckRepeatsEvery24Hours() async {
    suite.defaults.set(launch.addingTimeInterval(-Updater.checkInterval), forKey: Updater.lastCheckKey)
    let updater = updater(clock: clock(allowedSleeps: 2))

    await updater.runAutomaticChecks()

    #expect(feed.fetchCount == 2)
  }

  @Test func theAutomaticCheckIsSkippedWhenThePreferenceIsOff() async {
    store.preferences.checksForUpdates = false
    let updater = updater()

    await updater.runAutomaticChecks()

    #expect(feed.fetchCount == 0)
    #expect(updater.state == .idle)
  }

  @Test func theAutomaticCheckIsSkippedWhenTheLastCheckIsRecent() async {
    suite.defaults.set(launch.addingTimeInterval(-3_600), forKey: Updater.lastCheckKey)
    let updater = updater()

    await updater.runAutomaticChecks()

    #expect(feed.fetchCount == 0)
  }

  @Test func aRelaunchDoesNotCheckAgainWithin24Hours() async {
    await updater().runAutomaticChecks()
    #expect(feed.fetchCount == 1)

    await updater(clock: clock(startingAt: launch.addingTimeInterval(600))).runAutomaticChecks()

    #expect(feed.fetchCount == 1)
  }

  @Test func aRelaunchChecksAgainAfter24Hours() async {
    await updater().runAutomaticChecks()

    let later = launch.addingTimeInterval(Updater.checkInterval + 1)
    await updater(clock: clock(startingAt: later)).runAutomaticChecks()

    #expect(feed.fetchCount == 2)
  }

  @Test func anAutomaticFailureLeavesTheStateUntouched() async {
    feed.result = .failure(.noConnection)
    let updater = updater()

    await updater.runAutomaticChecks()

    #expect(updater.state == .idle)
    #expect(suite.defaults.object(forKey: Updater.lastCheckKey) == nil)
  }

  @Test func checksDefaultToOnAndDecodeFromOlderPreferences() throws {
    let older = Data(#"{"showsMinimap": false}"#.utf8)

    let decoded = try JSONDecoder().decode(Preferences.self, from: older)

    #expect(Preferences().checksForUpdates)
    #expect(decoded.checksForUpdates)
  }
}
