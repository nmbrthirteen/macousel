import AppKit
import CoreGraphics
import WindowSystem

final class SystemWindowProbe: WindowProbing {
  private let tracker: WindowTracker
  private let reader = WindowFactsReader()

  init(tracker: WindowTracker) {
    self.tracker = tracker
    tracker.observeTermination { [reader] pid in reader.forget(pid: pid) }
  }

  func probe(
    _ windows: [CGWindowID], includingFocus: Bool,
    completion: @escaping (WindowProbeResult) -> Void
  ) {
    let frontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier
    let focusedPID = includingFocus ? frontmost : nil
    reader.read(windows.compactMap { tracker.windows[$0] }, focusing: focusedPID) {
      [tracker] result in
      var tracked = result
      tracked.focusedWindow = result.focusedWindow.flatMap { tracker.windows[$0]?.id }
      completion(tracked)
    }
  }
}
