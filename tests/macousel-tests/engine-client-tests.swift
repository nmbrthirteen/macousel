import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct EngineClientTests {
  private let harness = EngineHarness()

  private func helper(in directory: TemporaryDirectory, body: String) throws -> URL {
    let url = directory.url.appendingPathComponent("helper.sh")
    try ("#!/bin/sh\n" + body).write(to: url, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    return url
  }

  private func recordingBody(in directory: TemporaryDirectory) -> String {
    let log = directory.url.appendingPathComponent("calls.log").path
    return """
      echo "$PANERU_MACH_SERVICE $@" >> '\(log)'
      if [ "$1" = "query" ] && [ "$2" = "state" ]; then
        printf '%s' '\(EngineFixtures.stateJSON)'
      fi
      if [ "$2" = "active" ] && [ -e '\(directory.url.path)/down' ]; then exit 1; fi
      exit 0
      """
  }

  private func calls(in directory: TemporaryDirectory) throws -> [String] {
    let text = try String(
      contentsOf: directory.url.appendingPathComponent("calls.log"), encoding: .utf8)
    return text.split(separator: "\n").map { String($0) }
  }

  @Test func sendsCommandsToThePrivateServiceAsSeparateArguments() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let script = try helper(in: directory, body: recordingBody(in: directory))
    let client = EngineClient(service: "dev.macousel.app.engine", locate: { script })

    await client.send(["window", "focus", "west"])

    #expect(try calls(in: directory) == ["dev.macousel.app.engine send-cmd window focus west"])
  }

  @Test func readsTheStateDocumentFromQueryState() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let script = try helper(in: directory, body: recordingBody(in: directory))
    let client = EngineClient(service: "dev.macousel.app.engine", locate: { script })

    let snapshot = await client.fetchSnapshot()

    #expect(snapshot?.tiledWindows.count == 3)
    #expect(try calls(in: directory) == ["dev.macousel.app.engine query state"])
  }

  @Test func reportsWhetherTheServiceAnswers() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let script = try helper(in: directory, body: recordingBody(in: directory))
    let client = EngineClient(service: EngineService.standalone, locate: { script })

    #expect(await client.isAnswering())
    FileManager.default.createFile(
      atPath: directory.url.appendingPathComponent("down").path, contents: nil)
    #expect(!(await client.isAnswering()))
    #expect(try calls(in: directory).first == "com.github.karinushka.paneru query active")
  }

  @Test func answersNothingWithoutAHelper() async {
    let client = EngineClient(service: "dev.macousel.app.engine", locate: { nil })

    #expect(await client.fetchSnapshot() == nil)
    #expect(!(await client.isAnswering()))
  }

  @Test func deliversDecodedEventsFromTheSubscribeChild() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let body = """
      echo '{"event":"window_focused","window_id":5,"bundle_id":"a","title":"t"}'
      echo '{"event":"display_changed","display_id":2}'
      """
    let script = try helper(in: directory, body: body)
    let subscriber = EngineSubscriber(
      service: "dev.macousel.app.engine", retryDelay: .seconds(3600), locate: { script })
    var received: [EngineEvent] = []
    subscriber.onEvent = { received.append($0) }

    subscriber.start()

    #expect(await harness.eventually { received.count == 2 })
    subscriber.stop()
    #expect(
      received == [
        .windowFocused(windowId: 5, bundleId: "a", title: "t", workspace: nil),
        .displayChanged(displayId: 2),
      ])
  }
}
