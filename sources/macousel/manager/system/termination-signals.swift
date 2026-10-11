import AppKit

final class TerminationSignals {
  private static let handledSignals = [SIGTERM, SIGINT]
  private nonisolated static let forcedExitDelay = DispatchTimeInterval.seconds(10)

  private let queue = DispatchQueue(label: "dev.macousel.app.termination-signals")
  private var sources: [any DispatchSourceSignal] = []

  func install() {
    guard sources.isEmpty else { return }
    let queue = queue
    sources = Self.handledSignals.map { number in
      signal(number, SIG_IGN)
      let source = DispatchSource.makeSignalSource(signal: number, queue: queue)
      source.setEventHandler { @Sendable in Self.terminate(escalatingOn: queue) }
      source.resume()
      return source
    }
  }

  private nonisolated static func terminate(escalatingOn queue: DispatchQueue) {
    DispatchQueue.main.async {
      MainActor.assumeIsolated { NSApplication.shared.terminate(nil) }
    }
    queue.asyncAfter(deadline: .now() + forcedExitDelay) { _exit(1) }
  }
}
