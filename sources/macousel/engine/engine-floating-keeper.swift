import CoreGraphics
import WindowSystem
import os

// The engine's own "window raise floating" focuses a floating window as it raises them, so
// Macousel raises the ones over the focused window itself, as the built-in engine does.
final class EngineFloatingKeeper {
  private static let logger = Logger(subsystem: Log.subsystem, category: "floating")

  var isSuppressed: () -> Bool = { false }

  private let store: PreferencesStore
  private let clock: any AnimationClock
  private let windows: any EngineWindowControl
  private let stackingOrder: () -> [CGWindowID]
  private var latest: EngineSnapshot?
  private var focusedWindow: Int32?
  private var generation = 0

  init(
    store: PreferencesStore, clock: any AnimationClock, windows: any EngineWindowControl,
    stackingOrder: @escaping () -> [CGWindowID]
  ) {
    self.store = store
    self.clock = clock
    self.windows = windows
    self.stackingOrder = stackingOrder
  }

  func adopted(_ snapshot: EngineSnapshot) {
    latest = snapshot
    let focused = snapshot.focusedWindow?.windowId
    guard focused != focusedWindow else { return }
    generation += 1
    focusedWindow = focused
    guard let focused, store.preferences.keepsFloatingWindowsOnTop else { return }
    let current = generation
    clock.schedule(after: FloatingWindowKeeper.raiseDelay) { [weak self] in
      guard let self, generation == current, !isSuppressed(), let latest else { return }
      let covering = Self.covering(focused, in: latest, frontToBack: stackingOrder())
      guard !covering.isEmpty else { return }
      windows.raise(covering.reversed())
      Self.logger.info("Raised \(covering.count, privacy: .public) floating windows")
    }
  }

  func cancel() {
    generation += 1
    focusedWindow = nil
    latest = nil
  }

  static func covering(
    _ window: Int32, in snapshot: EngineSnapshot, frontToBack order: [CGWindowID]
  ) -> [CGWindowID] {
    guard let focused = snapshot.visibleWindows.first(where: { $0.windowId == window }),
      let target = focused.frame?.rect
    else { return [] }
    let covering = snapshot.floatingWindows.compactMap { floating -> CGWindowID? in
      guard let frame = floating.frame?.rect, FloatingWindowKeeper.overlaps(frame, target),
        !Self.sharesApp(floating, focused)
      else { return nil }
      return CGWindowID(exactly: floating.windowId)
    }
    let rank = Dictionary(
      order.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
    return covering.sorted { (rank[$0] ?? Int.max) < (rank[$1] ?? Int.max) }
  }

  // Raising a window of the focused app makes it that app's focused window, so a browser's
  // picture-in-picture player would take the keyboard from the page.
  private static func sharesApp(_ first: EngineWindow, _ second: EngineWindow) -> Bool {
    !first.bundleId.isEmpty && first.bundleId == second.bundleId
  }
}
