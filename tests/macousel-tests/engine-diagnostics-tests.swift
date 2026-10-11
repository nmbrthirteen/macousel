import Foundation
import Testing
import WindowSystem

@testable import Macousel

@MainActor
struct EngineDiagnosticsTests {
  private let environment = DiagnosticsEnvironment(
    appVersion: "0.2.0", build: "7", osVersion: "Version 26.1", displays: [.fake()])

  private func saver(in directory: TemporaryDirectory) -> DiagnosticsSaver {
    DiagnosticsSaver(
      destination: directory.url, environment: environment,
      crashReports: CrashReportLister(directory: directory.url.appendingPathComponent("none")),
      logReader: FakeLogReader(result: .success("log")), now: { Date() })
  }

  private var report: EngineReport {
    EngineReport(
      selected: .paneru, version: "0.5.2", helperFound: true, state: "running", restartCount: 2,
      config: "[options]\nfocus_follows_mouse = false", logTail: "INFO started")
  }

  @Test func savesTheEngineSection() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }

    let file = try await saver(in: directory).save(preferences: Preferences(), engine: report)

    let text = try String(contentsOf: file, encoding: .utf8)
    #expect(text.contains("Engine: Paneru"))
    #expect(text.contains("Engine version: 0.5.2"))
    #expect(text.contains("Engine helper found: yes"))
    #expect(text.contains("Engine state: running, restarts 2"))
    #expect(text.contains("focus_follows_mouse = false"))
    #expect(text.contains("Engine log, last 200 lines\nINFO started"))
  }

  @Test func theHelperLineSaysNoWhenTheBinaryIsMissing() {
    var missing = report
    missing.helperFound = false

    #expect(missing.text.contains("Engine helper found: no"))
  }

  @Test func leavesTheSectionOutWhenThereIsNoEngineReport() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }

    let file = try await saver(in: directory).save(preferences: Preferences())

    #expect(!(try String(contentsOf: file, encoding: .utf8)).contains("Engine:"))
  }
}
