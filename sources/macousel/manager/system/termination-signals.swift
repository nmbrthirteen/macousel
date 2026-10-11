import AppKit

final class TerminationSignals {
  private static let handledSignals = [SIGTERM, SIGINT]

  private var sources: [any DispatchSourceSignal] = []

  func install() {
    guard sources.isEmpty else { return }
    sources = Self.handledSignals.map { number in
      signal(number, SIG_IGN)
      let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
      source.setEventHandler { NSApplication.shared.terminate(nil) }
      source.resume()
      return source
    }
  }
}
