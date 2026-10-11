import Foundation
import os

nonisolated final class AppResponsivenessBook: Sendable {
  struct Change: Sendable, Equatable {
    var bundleIdentifier: String?
    var isSlow: Bool
  }

  private struct State: Sendable {
    var apps: [pid_t: AppResponsiveness] = [:]
    var seeded: Set<String> = []
    var observer: (@Sendable (String, Bool) -> Void)?
  }

  private let state = OSAllocatedUnfairLock(initialState: State())

  func seed(_ bundleIdentifiers: Set<String>) {
    state.withLock { $0.seeded = bundleIdentifiers }
  }

  func observe(_ observer: @escaping @Sendable (String, Bool) -> Void) {
    state.withLock { $0.observer = observer }
  }

  func isSlow(_ pid: pid_t, bundleIdentifier: String?) -> Bool {
    state.withLock { Self.app(for: pid, bundleIdentifier, in: &$0).isSlow }
  }

  func record(_ pid: pid_t, bundleIdentifier: String?, milliseconds: Double) -> Change? {
    let change = state.withLock { state -> Change? in
      var app = Self.app(for: pid, bundleIdentifier, in: &state)
      let wasSlow = app.isSlow
      app.record(milliseconds: milliseconds)
      state.apps[pid] = app
      guard app.isSlow != wasSlow else { return nil }
      return Change(bundleIdentifier: bundleIdentifier, isSlow: app.isSlow)
    }
    guard let change else { return nil }
    if let bundle = change.bundleIdentifier, let observer = state.withLock({ $0.observer }) {
      observer(bundle, change.isSlow)
    }
    return change
  }

  private static func app(
    for pid: pid_t, _ bundleIdentifier: String?, in state: inout State
  ) -> AppResponsiveness {
    if let app = state.apps[pid] { return app }
    var seededSlow = false
    if let bundleIdentifier { seededSlow = state.seeded.contains(bundleIdentifier) }
    let app = AppResponsiveness(isSlow: seededSlow)
    state.apps[pid] = app
    return app
  }
}
