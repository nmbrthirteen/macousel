import ApplicationServices
import Foundation
import os

private nonisolated let logger = Logger(subsystem: "dev.macousel.app", category: "frame-applier")

nonisolated final class EnhancedInterfaceSuspender: Sendable {
  private struct Reading: Sendable {
    var isEnhanced: Bool
    var at: ContinuousClock.Instant
  }

  private static let attribute = "AXEnhancedUserInterface"
  private static let readingLifetime = Duration.seconds(5)

  private let suspended = OSAllocatedUnfairLock(initialState: Set<pid_t>())
  private let readings = OSAllocatedUnfairLock(initialState: [pid_t: Reading]())
  private let messagingTimeout: Float

  init(messagingTimeout: Float) {
    self.messagingTimeout = messagingTimeout
  }

  func suspend(_ pid: pid_t) {
    guard !suspended.withLock({ $0.contains(pid) }) else { return }
    let app = applicationElement(pid)
    guard isEnhanced(app, pid: pid) else { return }
    app.set(bool: false, for: Self.attribute)
    readings.withLock { $0[pid] = Reading(isEnhanced: false, at: .now) }
    suspended.withLock { _ = $0.insert(pid) }
    logger.info("pid \(pid, privacy: .public) enhanced interface switched off")
  }

  func restore(_ pid: pid_t) {
    guard suspended.withLock({ $0.remove(pid) != nil }) else { return }
    applicationElement(pid).set(bool: true, for: Self.attribute)
    readings.withLock { $0[pid] = Reading(isEnhanced: true, at: .now) }
    logger.info("pid \(pid, privacy: .public) enhanced interface restored")
  }

  private func isEnhanced(_ app: AXUIElement, pid: pid_t) -> Bool {
    if let cached = readings.withLock({ $0[pid] }),
      cached.at.duration(to: .now) < Self.readingLifetime
    {
      return cached.isEnhanced
    }
    let enhanced: Bool = app.attribute(Self.attribute) ?? false
    readings.withLock { $0[pid] = Reading(isEnhanced: enhanced, at: .now) }
    return enhanced
  }

  private func applicationElement(_ pid: pid_t) -> AXUIElement {
    let app = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(app, messagingTimeout)
    return app
  }
}
