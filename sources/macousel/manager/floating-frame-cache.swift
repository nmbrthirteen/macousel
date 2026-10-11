import CoreGraphics
import WindowSystem

final class FloatingFrameCache {
  private let probe: any WindowProbing
  private var frames: [CGWindowID: CGRect] = [:]
  private var inFlight: Set<CGWindowID> = []
  private var outdated: Set<CGWindowID> = []

  init(probe: any WindowProbing) {
    self.probe = probe
  }

  func frame(of window: CGWindowID) -> CGRect? {
    frames[window]
  }

  func record(_ frame: CGRect, for window: CGWindowID) {
    frames[window] = frame
  }

  func invalidate(_ window: CGWindowID) {
    frames[window] = nil
    if inFlight.contains(window) { outdated.insert(window) }
  }

  func retain(only alive: Set<CGWindowID>) {
    frames = frames.filter { alive.contains($0.key) }
  }

  func refresh(_ windows: [CGWindowID]) {
    let wanted = windows.filter { frames[$0] == nil && !inFlight.contains($0) }
    guard !wanted.isEmpty else { return }
    inFlight.formUnion(wanted)
    probe.probe(wanted, includingFocus: false) { [weak self] result in
      self?.received(result, for: wanted)
    }
  }

  private func received(_ result: WindowProbeResult, for requested: [CGWindowID]) {
    inFlight.subtract(requested)
    let retry = outdated.intersection(requested)
    outdated.subtract(requested)
    for id in requested where !retry.contains(id) {
      if let facts = result.facts[id], !facts.timedOut, let frame = facts.frame {
        frames[id] = frame
      }
    }
    refresh(Array(retry))
  }
}
