import CoreGraphics
import WindowSystem

@testable import Macousel

@MainActor
final class FakeWindowProbe: WindowProbing {
  struct Request: Equatable {
    var windows: [CGWindowID]
    var includesFocus: Bool
  }

  var defersResults = false
  private(set) var requests: [Request] = []
  private var held: [() -> Void] = []
  private let source: FakeWindowSource

  init(source: FakeWindowSource) {
    self.source = source
  }

  var probeCount: Int { requests.count }
  var heldCount: Int { held.count }

  func probe(
    _ windows: [CGWindowID], includingFocus: Bool,
    completion: @escaping (WindowProbeResult) -> Void
  ) {
    requests.append(Request(windows: windows, includesFocus: includingFocus))
    let result = read(windows, includingFocus: includingFocus)
    if defersResults {
      held.append { completion(result) }
    } else {
      completion(result)
    }
  }

  func releaseHeldResults() {
    let releasing = held
    held = []
    for deliver in releasing { deliver() }
  }

  private func read(_ windows: [CGWindowID], includingFocus: Bool) -> WindowProbeResult {
    var facts: [CGWindowID: WindowFacts] = [:]
    for id in windows {
      guard let window = source.fakeWindow(id) else { continue }
      facts[id] = WindowFacts(
        isTileable: window.isTileable, isFullScreen: window.isFullScreen, frame: window.frame,
        title: window.title, timedOut: window.timesOutReads)
    }
    let focused = includingFocus ? source.focusedWindow()?.id : nil
    return WindowProbeResult(facts: facts, focusedWindow: focused)
  }
}
