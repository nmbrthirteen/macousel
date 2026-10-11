import CoreGraphics
import Foundation
import Testing
import WindowSystem

@testable import Macousel

@MainActor
struct DiagnosticsTests {
  private struct LogFailure: Error {}

  private let environment = DiagnosticsEnvironment(
    appVersion: "0.2.0", build: "7", osVersion: "Version 26.1 (Build 25B1)",
    displays: [.fake()])

  private func fixedDate() throws -> Date {
    let parts = DateComponents(year: 2026, month: 10, day: 11, hour: 14, minute: 5)
    return try #require(Calendar.current.date(from: parts))
  }

  private func saver(
    in directory: TemporaryDirectory, reports: URL? = nil, log: Result<String, any Error>
  ) throws -> DiagnosticsSaver {
    DiagnosticsSaver(
      destination: directory.url, environment: environment,
      crashReports: CrashReportLister(directory: reports ?? directory.url.appendingPathComponent("none")),
      logReader: FakeLogReader(result: log), now: { (try? fixedDate()) ?? Date() })
  }

  private func contents(of file: URL) throws -> String {
    try String(contentsOf: file, encoding: .utf8)
  }

  @Test func fileIsNamedWithTheMinuteItWasSaved() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }

    let file = try await saver(in: directory, log: .success("")).save(preferences: Preferences())

    #expect(file.lastPathComponent == "Macousel diagnostics 2026-10-11 14.05.txt")
    #expect(file.deletingLastPathComponent().standardizedFileURL == directory.url.standardizedFileURL)
  }

  @Test func sectionsAppearInTheDocumentedOrder() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let reports = try TemporaryDirectory()
    defer { reports.remove() }
    FileManager.default.createFile(
      atPath: reports.url.appendingPathComponent("Macousel-2026-10-10.ips").path, contents: nil)

    let file = try await saver(in: directory, reports: reports.url, log: .success("LOG-LINE"))
      .save(preferences: Preferences())

    let text = try contents(of: file)
    let markers = [
      "App version: 0.2.0 (build 7)", "macOS: Version 26.1 (Build 25B1)", "Displays",
      "Display 1: frame x 0.0 y 0.0 width 1000.0 height 800.0, visible x 0.0 y 24.0",
      "Preferences", "Crash reports", "Macousel-2026-10-10.ips", "LOG-LINE",
    ]
    let positions = try markers.map { marker in
      try #require(text.range(of: marker)?.lowerBound, "missing \(marker)")
    }
    #expect(positions == positions.sorted())
  }

  @Test func preferencesArePrettyPrintedWithSortedKeys() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }

    let file = try await saver(in: directory, log: .success("")).save(preferences: Preferences())

    let text = try contents(of: file)
    let animation = try #require(text.range(of: "\"animationSpeed\""))
    let border = try #require(text.range(of: "\"focusBorderWidth\""))
    let updates = try #require(text.range(of: "\"checksForUpdates\""))
    #expect(animation.lowerBound < updates.lowerBound)
    #expect(updates.lowerBound < border.lowerBound)
    #expect(text.contains("\n  \"showsMinimap\" : true"))
  }

  @Test func onlyReportsStartingWithMacousel() throws {
    let reports = try TemporaryDirectory()
    defer { reports.remove() }
    for name in ["Macousel-b.ips", "Macousel-a.ips", "Safari-1.ips", "macousel-lower.ips"] {
      FileManager.default.createFile(
        atPath: reports.url.appendingPathComponent(name).path, contents: nil)
    }

    #expect(CrashReportLister(directory: reports.url).names == ["Macousel-a.ips", "Macousel-b.ips"])
  }

  @Test func missingReportsFolderListsNothingAndSaysSo() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }

    let file = try await saver(in: directory, log: .success("")).save(preferences: Preferences())

    #expect(try contents(of: file).contains("Crash reports\nNone"))
  }

  @Test func failedLogReadIsWrittenInPlaceAndTheRestIsStillSaved() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let failure = SystemLogReader.Failure(status: 64, output: "log: permission denied")

    let file = try await saver(in: directory, log: .failure(failure)).save(
      preferences: Preferences())

    let text = try contents(of: file)
    #expect(text.contains("The log could not be read (exit status 64). log: permission denied"))
    #expect(text.contains("App version: 0.2.0 (build 7)"))
    #expect(text.contains("\"showsMinimap\""))
  }

  @Test func unexpectedLogErrorsAreWrittenInPlace() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }

    let file = try await saver(in: directory, log: .failure(LogFailure())).save(
      preferences: Preferences())

    #expect(try contents(of: file).contains("The log could not be read."))
  }

  @Test func savingToAMissingFolderThrows() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    var missing = try saver(in: directory, log: .success(""))
    missing = DiagnosticsSaver(
      destination: directory.url.appendingPathComponent("gone"), environment: environment,
      crashReports: missing.crashReports, logReader: missing.logReader, now: missing.now)

    await #expect(throws: (any Error).self) {
      try await missing.save(preferences: Preferences())
    }
  }
}
