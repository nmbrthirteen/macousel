import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct EngineBridgeTests {
  private let harness = EngineHarness()

  private func script(in directory: TemporaryDirectory, named name: String, body: String) throws
    -> URL
  {
    let url = directory.url.appendingPathComponent(name)
    try ("#!/bin/sh\n" + body).write(to: url, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    return url
  }

  private func lines(in directory: TemporaryDirectory, _ name: String) -> [String] {
    let text = try? String(
      contentsOf: directory.url.appendingPathComponent(name), encoding: .utf8)
    return (text ?? "").split(separator: "\n").map { String($0) }
  }

  private static let readID = #"id=$(printf '%s' "$line" | sed 's/.*"id":\([0-9]*\).*/\1/')"#
  private static let readWord =
    #"word=$(printf '%s' "$line" | sed -n 's/.*"words":\["\([a-z]*\)".*/\1/p')"#

  // Answers every request in turn: a snapshot with the fixture state, a command with nothing.
  private func answeringBody(in directory: TemporaryDirectory) -> String {
    let log = directory.url.appendingPathComponent("requests.log").path
    return """
      echo "$PANERU_MACH_SERVICE $@" >> '\(directory.url.path)/launches.log'
      while read -r line; do
        \(Self.readID)
        \(Self.readWord)
        if [ "$word" = "slow" ]; then sleep 0.3; fi
        if [ "$word" = "stall" ]; then sleep 3600; fi
        echo "${word:-snapshot}" >> '\(log)'
        if [ -z "$word" ]; then
          printf '{"id":%s,"state":%s,"layout":null}\\n' "$id" '\(EngineFixtures.stateJSON)'
        else
          printf '{"id":%s}\\n' "$id"
        fi
      done
      """
  }

  @Test func answersSnapshotsAndCommandsFromOneChild() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let bridge = try script(in: directory, named: "bridge", body: answeringBody(in: directory))
    let connection = EngineBridgeConnection(service: "dev.macousel.app.engine", locate: { bridge })
    let client = EngineClient(
      service: "dev.macousel.app.engine", locate: { nil }, bridge: connection)

    let snapshot = await client.fetchSnapshot()
    await client.send(["window", "focus", "west"])
    let again = await client.fetchSnapshot()
    connection.close()

    #expect(snapshot?.tiledWindows.count == 3)
    #expect(again == snapshot)
    #expect(lines(in: directory, "requests.log") == ["snapshot", "window", "snapshot"])
    #expect(lines(in: directory, "launches.log") == ["dev.macousel.app.engine serve"])
  }

  @Test func matchesAnswersToRequestsByIDWhenTheyArriveOutOfOrder() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let body = """
      read -r line
      \(Self.readID)
      first=$id
      \(Self.readWord)
      firstWord=$word
      read -r line
      \(Self.readID)
      \(Self.readWord)
      printf '{"id":%s,"error":"%s"}\\n' "$id" "$word"
      printf '{"id":%s,"error":"%s"}\\n' "$first" "$firstWord"
      while read -r line; do :; done
      """
    let bridge = try script(in: directory, named: "bridge", body: body)
    let connection = EngineBridgeConnection(service: "dev.macousel.app.engine", locate: { bridge })

    let first = Task { await connection.ask(.command(["alpha"])) }
    let second = Task { await connection.ask(.command(["beta"])) }
    let firstOutcome = await first.value
    let secondOutcome = await second.value
    connection.close()

    #expect(firstOutcome == .answered(EngineBridgeAnswer(id: 1, error: "alpha")))
    #expect(secondOutcome == .answered(EngineBridgeAnswer(id: 2, error: "beta")))
  }

  @Test func deliversCommandsInTheOrderTheyWereIssued() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let bridge = try script(in: directory, named: "bridge", body: answeringBody(in: directory))
    let connection = EngineBridgeConnection(service: "dev.macousel.app.engine", locate: { bridge })
    let client = EngineClient(
      service: "dev.macousel.app.engine", locate: { nil }, bridge: connection)

    let first = Task { await client.send(["slow"]) }
    let second = Task { await client.send(["fast"]) }
    await first.value
    await second.value
    connection.close()

    #expect(lines(in: directory, "requests.log") == ["slow", "fast"])
  }

  @Test func restartsTheChildWhenARequestTimesOut() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let bridge = try script(in: directory, named: "bridge", body: answeringBody(in: directory))
    var timeouts: [Duration] = []
    var held: [CheckedContinuation<Void, Never>] = []
    // The first request times out at once; later ones wait for their answer however slow.
    let connection = EngineBridgeConnection(
      service: "dev.macousel.app.engine",
      sleep: { duration in
        timeouts.append(duration)
        if timeouts.count > 1 { await withCheckedContinuation { held.append($0) } }
      },
      locate: { bridge })

    let lost = await connection.ask(.command(["stall"]))
    let answered = await connection.ask(.command(["window", "snap"]))
    connection.close()
    held.forEach { $0.resume() }

    #expect(timeouts.first == .seconds(HelperRunner.standardTimeout))
    #expect(lost == .failed)
    #expect(answered == .answered(EngineBridgeAnswer(id: 2)))
    #expect(lines(in: directory, "requests.log").last == "window")
  }

  @Test func spawnsHelpersWhenTheBridgeIsMissing() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let log = directory.url.appendingPathComponent("calls.log").path
    let helper = try script(
      in: directory, named: "helper",
      body: """
        echo "$@" >> '\(log)'
        if [ "$1" = "query" ]; then printf '%s' '\(EngineFixtures.stateJSON)'; fi
        """)
    let connection = EngineBridgeConnection(service: "dev.macousel.app.engine", locate: { nil })
    let client = EngineClient(
      service: "dev.macousel.app.engine", locate: { helper }, bridge: connection)

    let snapshot = await client.fetchSnapshot()
    await client.send(["window", "snap"])

    #expect(snapshot?.tiledWindows.count == 3)
    #expect(lines(in: directory, "calls.log") == ["query state", "send-cmd window snap"])
  }

  @Test func givesUpOnABridgeThatKeepsExiting() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let bridge = try script(in: directory, named: "bridge", body: "exit 1")
    let connection = EngineBridgeConnection(service: "dev.macousel.app.engine", locate: { bridge })

    var outcomes: [EngineBridgeConnection.Outcome] = []
    for _ in 0...EngineBridgeConnection.maximumFailures {
      outcomes.append(await connection.ask(.snapshot))
    }

    #expect(
      outcomes
        == Array(repeating: .failed, count: EngineBridgeConnection.maximumFailures)
        + [.unavailable])
  }

  @Test func routesEventLinesToTheSubscriber() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let body = """
      echo '{"event":"window_focused","window_id":5,"bundle_id":"a","title":"t"}'
      echo '{"event":"display_changed","display_id":2}'
      while read -r line; do :; done
      """
    let bridge = try script(in: directory, named: "bridge", body: body)
    let connection = EngineBridgeConnection(service: "dev.macousel.app.engine", locate: { bridge })
    let subscriber = EngineSubscriber(
      service: "dev.macousel.app.engine", retryDelay: .seconds(3600), bridge: connection,
      locate: { nil })
    var received: [EngineEvent] = []
    var connects = 0
    subscriber.onEvent = { received.append($0) }
    subscriber.onConnect = { connects += 1 }

    subscriber.start()

    #expect(await harness.eventually { received.count == 2 })
    subscriber.stop()
    #expect(
      received == [
        .windowFocused(windowId: 5, bundleId: "a", title: "t", workspace: nil),
        .displayChanged(displayId: 2),
      ])
    #expect(connects == 1)
  }

  @Test func connectsOnTheFirstAnswerBeforeAnyEvent() async throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let bridge = try script(in: directory, named: "bridge", body: answeringBody(in: directory))
    let connection = EngineBridgeConnection(service: "dev.macousel.app.engine", locate: { bridge })
    let subscriber = EngineSubscriber(
      service: "dev.macousel.app.engine", retryDelay: .seconds(3600), bridge: connection,
      locate: { nil })
    var connects = 0
    subscriber.onConnect = { connects += 1 }

    subscriber.start()
    for _ in 0..<10 { await Task.yield() }
    #expect(connects == 0)
    _ = await connection.ask(.snapshot)
    _ = await connection.ask(.snapshot)

    #expect(await harness.eventually { connects == 1 })
    subscriber.stop()
    #expect(connects == 1)
  }

  @Test func wakesAPollerOnTheNextEvent() async throws {
    let world = EngineWorld(
      commands: FakeEngineCommands(log: EngineCallLog()),
      sleep: { try await Task.sleep(for: $0) })
    let started = ContinuousClock.now

    let waiting = Task { try await world.awaitEvent(upTo: .seconds(30)) }
    for _ in 0..<10 { await Task.yield() }
    world.handle(.displayChanged(displayId: 1))
    try await waiting.value

    #expect(ContinuousClock.now - started < .seconds(5))
  }
}
