import CoreGraphics

@testable import Macousel

@MainActor
final class FakeFramePlacer: FramePlacer {
  struct Submission: Equatable {
    var window: CGWindowID
    var frame: CGRect
  }

  var isIdle = true
  var holdsPlacementWork = false
  var onSlowAppChange: ((_ bundleIdentifier: String, _ isSlow: Bool) -> Void)?
  var sequence: EventSequence?
  private var slowApps: Set<pid_t> = []
  private var slowBundles: Set<String> = []
  private var held: [() -> Void] = []
  private(set) var submissions: [Submission] = []
  private(set) var forgotten: [CGWindowID] = []
  private(set) var flushCount = 0
  private(set) var requestedTimeouts: [Duration] = []

  func submit(_ frame: CGRect, for window: any WindowHandle) {
    submissions.append(Submission(window: window.id, frame: frame))
    sequence?.record(.frameSubmitted(window.id))
    window.setFrame(frame)
  }

  func afterPlacement(
    of window: any WindowHandle, within timeout: Duration, _ action: @escaping () -> Void
  ) {
    requestedTimeouts.append(timeout)
    if holdsPlacementWork {
      held.append(action)
    } else {
      action()
    }
  }

  func timeOutHeldPlacementWork() {
    let actions = held
    held = []
    for action in actions { action() }
  }

  func isSlowApp(of window: any WindowHandle) -> Bool {
    slowApps.contains(window.pid)
      || window.bundleIdentifier.map { slowBundles.contains($0) } == true
  }

  func seedSlowApps(_ bundleIdentifiers: Set<String>) {
    slowBundles = bundleIdentifiers
  }

  func setSlow(_ isSlow: Bool, forAppOf window: any WindowHandle) {
    if isSlow {
      slowApps.insert(window.pid)
    } else {
      slowApps.remove(window.pid)
      if let bundle = window.bundleIdentifier { slowBundles.remove(bundle) }
    }
    if let bundle = window.bundleIdentifier { onSlowAppChange?(bundle, isSlow) }
  }

  func flush() {
    flushCount += 1
  }

  func forget(_ window: CGWindowID) {
    forgotten.append(window)
  }
}
