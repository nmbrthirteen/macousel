import Observation
import Foundation
import WindowSystem

@Observable
final class AccessibilityStatus {
  // Backs up the trust notification only while a view shows the status and access is missing.
  private static let pollInterval = Duration.seconds(1)

  private(set) var isGranted = AccessibilityPermission.isGranted
  @ObservationIgnored private let trust = AccessibilityTrustObserver()
  @ObservationIgnored private var pollTask: Task<Void, Never>?

  func startPolling() {
    stopPolling()
    refresh()
    trust.onChange = { [weak self] in self?.refresh() }
    guard !isGranted else { return }
    pollTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: Self.pollInterval)
        guard let self, !Task.isCancelled else { return }
        self.refresh()
        if self.isGranted { return }
      }
    }
  }

  func stopPolling() {
    trust.onChange = nil
    pollTask?.cancel()
    pollTask = nil
  }

  private func refresh() {
    isGranted = AccessibilityPermission.isGranted
  }
}
