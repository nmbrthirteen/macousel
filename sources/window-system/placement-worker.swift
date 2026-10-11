import ApplicationServices
import CoreGraphics
import Foundation
import os

private nonisolated let logger = Logger(subsystem: "dev.macousel.app", category: "frame-applier")

nonisolated final class PlacementWorker: Sendable {
  private let sizes = OSAllocatedUnfairLock(initialState: [CGWindowID: CGSize]())
  private let timings = OSAllocatedUnfairLock(initialState: [pid_t: BurstTiming]())
  private let responsiveness = AppResponsivenessBook()
  private let enhancedInterface: EnhancedInterfaceSuspender

  init(messagingTimeout: Float) {
    enhancedInterface = EnhancedInterfaceSuspender(messagingTimeout: messagingTimeout)
  }

  func apply(_ window: CGWindowID, _ placement: PlacementRequest) {
    let started = ContinuousClock.now
    place(window, placement)
    let milliseconds = started.duration(to: .now).fractionalMilliseconds
    timings.withLock { $0[placement.pid, default: BurstTiming()].record(milliseconds: milliseconds) }
    classify(placement, afterSetTaking: milliseconds)
  }

  func isSlow(_ pid: pid_t, bundleIdentifier: String?) -> Bool {
    responsiveness.isSlow(pid, bundleIdentifier: bundleIdentifier)
  }

  func seedSlowApps(_ bundleIdentifiers: Set<String>) {
    responsiveness.seed(bundleIdentifiers)
  }

  func observeSlowChanges(_ observer: @escaping @Sendable (String, Bool) -> Void) {
    responsiveness.observe(observer)
  }

  private func classify(_ placement: PlacementRequest, afterSetTaking milliseconds: Double) {
    let change = responsiveness.record(
      placement.pid, bundleIdentifier: placement.bundleIdentifier, milliseconds: milliseconds)
    guard let change else { return }
    let state = change.isSlow ? "slow" : "responsive"
    let bundle = change.bundleIdentifier ?? "unknown"
    logger.info(
      "pid \(placement.pid, privacy: .public) is now \(state, privacy: .public) bundle \(bundle, privacy: .public)"
    )
  }

  private func place(_ window: CGWindowID, _ placement: PlacementRequest) {
    let element = placement.element.element
    let frame = placement.frame
    if sizes.withLock({ $0[window] }) == frame.size {
      element.set(point: frame.origin, for: kAXPositionAttribute)
      return
    }
    let sized = element.set(size: frame.size, for: kAXSizeAttribute)
    element.set(point: frame.origin, for: kAXPositionAttribute)
    element.set(size: frame.size, for: kAXSizeAttribute)
    if sized { sizes.withLock { $0[window] = frame.size } }
  }

  func forget(_ window: CGWindowID) {
    sizes.withLock { $0[window] = nil }
  }

  func beginBurst(of pid: pid_t) {
    timings.withLock { $0[pid] = nil }
    enhancedInterface.suspend(pid)
  }

  func endBurst(of pid: pid_t) {
    guard let timing = timings.withLock({ $0.removeValue(forKey: pid) }) else { return }
    logger.info(
      "pid \(pid, privacy: .public) applies \(timing.count, privacy: .public) timed out \(timing.timedOutCount, privacy: .public) average \(timing.averageMilliseconds, format: .fixed(precision: 1), privacy: .public) ms maximum \(timing.maximumMilliseconds, format: .fixed(precision: 1), privacy: .public) ms"
    )
  }

  func restoreEnhancedInterface(of pid: pid_t) {
    enhancedInterface.restore(pid)
  }
}
