import Foundation
import Testing

@testable import Macousel

@MainActor
struct EngineHelperTests {
  private func locator(
    files: [String: String], executable: String? = nil, bundle: String = "/Apps/Macousel.app"
  ) -> EngineHelperLocator {
    EngineHelperLocator(
      bundleURL: URL(fileURLWithPath: bundle), executableURL: executable.map { URL(fileURLWithPath: $0) },
      fileExists: { files[$0] != nil }, contents: { files[$0] })
  }

  @Test func prefersTheHelperInsideTheBundle() {
    let files = ["/Apps/Macousel.app/Contents/Helpers/paneru": ""]

    #expect(locator(files: files).helper?.path == "/Apps/Macousel.app/Contents/Helpers/paneru")
  }

  @Test func findsTheBridgeBesideTheHelper() {
    let bundled = ["/Apps/Macousel.app/Contents/Helpers/engine-bridge": ""]
    let built = [
      "/work/macousel/support/engine-version": "0.5.2\n",
      "/work/macousel/build/engine-0.5.2/bin/engine-bridge": "",
    ]
    let checkout = locator(files: built, executable: "/work/macousel/.build/debug/Macousel")

    #expect(
      locator(files: bundled).bridge?.path == "/Apps/Macousel.app/Contents/Helpers/engine-bridge")
    #expect(checkout.bridge?.path == "/work/macousel/build/engine-0.5.2/bin/engine-bridge")
    #expect(locator(files: [:]).bridge == nil)
  }

  @Test func fallsBackToTheDevelopmentBuildOfTheEngine() {
    let files = [
      "/work/macousel/support/engine-version": "0.5.2\n",
      "/work/macousel/build/engine-0.5.2/bin/paneru": "",
    ]
    let found = locator(files: files, executable: "/work/macousel/.build/debug/Macousel")

    #expect(found.helper?.path == "/work/macousel/build/engine-0.5.2/bin/paneru")
    #expect(found.version == "0.5.2")
  }

  @Test func reportsNoHelperWhenNothingWasBuilt() {
    let files = ["/work/macousel/support/engine-version": "0.5.2"]

    #expect(locator(files: files, executable: "/work/macousel/.build/debug/Macousel").helper == nil)
    #expect(locator(files: [:], executable: "/tmp/Macousel").helper == nil)
  }

  @Test func readsTheBundledVersionFirst() {
    let files = ["/Apps/Macousel.app/Contents/Resources/engine-version": "0.6.0\n"]

    #expect(locator(files: files).version == "0.6.0")
    #expect(locator(files: [:]).version == "unknown")
  }

  @Test func namesThePrivateServiceAfterTheBundle() {
    #expect(EngineService.privateName(bundleIdentifier: "dev.macousel.app") == "dev.macousel.app.engine")
    #expect(EngineService.standalone == "com.github.karinushka.paneru")
  }

  @Test func launchesTheDaemonWithPrivatePathsAndQuietLogs() {
    let paths = EnginePaths(
      support: URL(fileURLWithPath: "/Users/me/Library/Application Support/Macousel/engine"),
      logs: URL(fileURLWithPath: "/Users/me/Library/Logs/Macousel"))

    let launch = EngineLaunch.daemon(
      helper: URL(fileURLWithPath: "/Apps/Macousel.app/Contents/Helpers/paneru"), paths: paths,
      service: "dev.macousel.app.engine", base: ["HOME": "/Users/me", "NO_COLOR": "0"])

    #expect(launch.arguments.isEmpty)
    #expect(launch.environment["PANERU_MACH_SERVICE"] == "dev.macousel.app.engine")
    #expect(
      launch.environment["PANERU_CONFIG"]
        == "/Users/me/Library/Application Support/Macousel/engine/paneru.toml")
    #expect(
      launch.environment["XDG_STATE_HOME"]
        == "/Users/me/Library/Application Support/Macousel/engine/state")
    #expect(
      launch.environment["XDG_CONFIG_HOME"]
        == "/Users/me/Library/Application Support/Macousel/engine/config")
    #expect(launch.environment["NO_COLOR"] == "1")
    #expect(launch.environment["RUST_LOG"] == "info")
    #expect(launch.environment["HOME"] == "/Users/me")
    #expect(paths.log.path == "/Users/me/Library/Logs/Macousel/engine.log")
  }

  @Test func allowsThreeRestartsInAMinuteWithGrowingDelays() {
    var policy = EngineRestartPolicy()
    let start = ContinuousClock.now

    #expect(policy.decide(at: start) == .restart(after: .seconds(1)))
    #expect(policy.decide(at: start) == .restart(after: .seconds(2)))
    #expect(policy.decide(at: start) == .restart(after: .seconds(4)))
    #expect(policy.decide(at: start) == .giveUp)
  }

  @Test func forgetsRestartsAfterAMinute() {
    var policy = EngineRestartPolicy()
    let start = ContinuousClock.now
    for _ in 0..<3 { _ = policy.decide(at: start) }

    #expect(policy.decide(at: start + .seconds(61)) == .restart(after: .seconds(1)))
  }

  @Test func rotatesTheLogAtOneMegabyteKeepingOnePreviousFile() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let log = EngineLog(url: directory.url.appendingPathComponent("logs/engine.log"))
    log.append(Data(count: Int(EngineLog.rotationSize)))

    log.append(Data("fresh line\n".utf8))

    #expect(try String(contentsOf: log.url, encoding: .utf8) == "fresh line\n")
    #expect(FileManager.default.fileExists(atPath: log.previous.path))
    #expect(try Data(contentsOf: log.previous).count == Int(EngineLog.rotationSize))
  }

  @Test func appendsBelowTheLimitWithoutRotating() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let log = EngineLog(url: directory.url.appendingPathComponent("engine.log"))

    log.append(Data("one\n".utf8))
    log.append(Data("two\n".utf8))

    #expect(try String(contentsOf: log.url, encoding: .utf8) == "one\ntwo\n")
    #expect(!FileManager.default.fileExists(atPath: log.previous.path))
  }

  @Test func returnsTheLastLinesOfTheLog() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let log = EngineLog(url: directory.url.appendingPathComponent("engine.log"))
    log.append(Data((1...300).map { "line \($0)\n" }.joined().utf8))

    let tail = log.lastLines(200).split(separator: "\n", omittingEmptySubsequences: true)

    #expect(tail.count == 200)
    #expect(tail.last == "line 300")
    #expect(log.lastLines(5).isEmpty == false)
    #expect(EngineLog(url: directory.url.appendingPathComponent("none.log")).lastLines(5) == "")
  }
}
