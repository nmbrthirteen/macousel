import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import os

private nonisolated let logger = Logger(subsystem: "dev.macousel.app", category: "frame-applier")

nonisolated final class PlacementWorker: Sendable {
  private let sizes = OSAllocatedUnfairLock(initialState: [CGWindowID: CGSize]())
  private let timings = OSAllocatedUnfairLock(initialState: [pid_t: BurstTiming]())
  private let responsiveness = OSAllocatedUnfairLock(
    initialState: [pid_t: AppResponsiveness]())
  private let enhancedInterface: EnhancedInterfaceSuspender

  init(messagingTimeout: Float) {
    enhancedInterface = EnhancedInterfaceSuspender(messagingTimeout: messagingTimeout)
  }

  func apply(_ window: CGWindowID, _ placement: PlacementRequest) {
    let started = ContinuousClock.now
    place(window, placement)
    let milliseconds = started.duration(to: .now).fractionalMilliseconds
    timings.withLock { $0[placement.pid, default: BurstTiming()].record(milliseconds: milliseconds) }
    classify(placement.pid, afterSetTaking: milliseconds)
  }

  func isSlow(_ pid: pid_t) -> Bool {
    responsiveness.withLock { $0[pid]?.isSlow ?? false }
  }

  private func classify(_ pid: pid_t, afterSetTaking milliseconds: Double) {
    let change = responsiveness.withLock { all -> Bool? in
      var app = all[pid, default: AppResponsiveness()]
      let wasSlow = app.isSlow
      app.record(milliseconds: milliseconds)
      all[pid] = app
      return app.isSlow == wasSlow ? nil : app.isSlow
    }
    guard let isSlow = change else { return }
    let state = isSlow ? "slow" : "responsive"
    let bundle = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier ?? "unknown"
    logger.info(
      "pid \(pid, privacy: .public) is now \(state, privacy: .public) bundle \(bundle, privacy: .public)"
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
