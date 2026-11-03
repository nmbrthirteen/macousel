import Foundation

public final class AccessibilityTrustObserver {
  // macOS posts this whenever any app's Accessibility grant changes. The new trust value can
  // lag the notification, so each change is checked again a moment later.
  private static let notification = Notification.Name("com.apple.accessibility.api")
  private static let recheckDelay = Duration.milliseconds(500)

  public var onChange: (() -> Void)? {
    didSet { onChange == nil ? stop() : start() }
  }

  private var token: (any NSObjectProtocol)?
  private var recheck: Task<Void, Never>?

  public init() {}

  isolated deinit {
    stop()
  }

  private func start() {
    guard token == nil else { return }
    token = DistributedNotificationCenter.default().addObserver(
      forName: Self.notification, object: nil, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated { self?.changed() }
    }
  }

  private func stop() {
    if let token { DistributedNotificationCenter.default().removeObserver(token) }
    token = nil
    recheck?.cancel()
    recheck = nil
  }

  private func changed() {
    onChange?()
    guard token != nil else { return }
    recheck?.cancel()
    recheck = Task { [weak self] in
      try? await Task.sleep(for: Self.recheckDelay)
      if Task.isCancelled { return }
      self?.onChange?()
    }
  }
}
