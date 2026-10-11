import ApplicationServices
import CoreGraphics
import Foundation
import os

private nonisolated let logger = Logger(subsystem: "dev.macousel.app", category: "frame-applier")

nonisolated final class PlacementWorker: Sendable {
  private struct RecentAverage: Sendable {
    var seconds: Double
    var at: ContinuousClock.Instant
  }

  private struct EnhancedReading: Sendable {
    var isEnhanced: Bool
    var at: ContinuousClock.Instant
  }

  private static let enhancedInterface = "AXEnhancedUserInterface"
  private static let enhancedInterfaceCacheLifetime = Duration.seconds(5)
  private static let recentWindow = Duration.seconds(1)

  private let sizes = OSAllocatedUnfairLock(initialState: [CGWindowID: CGSize]())
  private let suspended = OSAllocatedUnfairLock(initialState: Set<pid_t>())
  private let timings = OSAllocatedUnfairLock(initialState: [pid_t: BurstTiming]())
  private let recentAverages = OSAllocatedUnfairLock(initialState: [pid_t: RecentAverage]())
  private let enhancedReadings = OSAllocatedUnfairLock(initialState: [pid_t: EnhancedReading]())
  private let messagingTimeout: Float

  init(messagingTimeout: Float) {
    self.messagingTimeout = messagingTimeout
  }

  func apply(_ window: CGWindowID, _ placement: PlacementRequest) {
    let started = ContinuousClock.now
    place(window, placement)
    let elapsed = started.duration(to: .now)
    let average = timings.withLock { timings -> Double in
      timings[placement.pid, default: BurstTiming()].record(elapsed)
      return (timings[placement.pid]?.averageMilliseconds ?? 0) / 1_000
    }
    recentAverages.withLock {
      $0[placement.pid] = RecentAverage(seconds: average, at: .now)
    }
  }

  func slowestRecentAverage(busy: Set<pid_t>) -> Double {
    recentAverages.withLock { averages in
      averages = averages.filter {
        busy.contains($0.key) || $0.value.at.duration(to: .now) < Self.recentWindow
      }
      return averages.values.map(\.seconds).max() ?? 0
    }
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
    disableEnhancedInterface(of: pid)
  }

  func endBurst(of pid: pid_t) {
    reportTiming(of: pid)
    restoreEnhancedInterface(of: pid)
  }

  private func reportTiming(of pid: pid_t) {
    guard let timing = timings.withLock({ $0.removeValue(forKey: pid) }) else { return }
    logger.info(
      "pid \(pid, privacy: .public) applies \(timing.count, privacy: .public) average \(timing.averageMilliseconds, format: .fixed(precision: 1), privacy: .public) ms maximum \(timing.maximumMilliseconds, format: .fixed(precision: 1), privacy: .public) ms"
    )
  }

  private func disableEnhancedInterface(of pid: pid_t) {
    let app = applicationElement(pid)
    guard isEnhanced(app, pid: pid) else { return }
    app.set(bool: false, for: Self.enhancedInterface)
    suspended.withLock { _ = $0.insert(pid) }
  }

  private func isEnhanced(_ app: AXUIElement, pid: pid_t) -> Bool {
    let cached = enhancedReadings.withLock { $0[pid] }
    if let cached, cached.at.duration(to: .now) < Self.enhancedInterfaceCacheLifetime {
      return cached.isEnhanced
    }
    let enhanced: Bool = app.attribute(Self.enhancedInterface) ?? false
    enhancedReadings.withLock { $0[pid] = EnhancedReading(isEnhanced: enhanced, at: .now) }
    return enhanced
  }

  private func restoreEnhancedInterface(of pid: pid_t) {
    guard suspended.withLock({ $0.remove(pid) != nil }) else { return }
    applicationElement(pid).set(bool: true, for: Self.enhancedInterface)
  }

  private func applicationElement(_ pid: pid_t) -> AXUIElement {
    let app = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(app, messagingTimeout)
    return app
  }
}
