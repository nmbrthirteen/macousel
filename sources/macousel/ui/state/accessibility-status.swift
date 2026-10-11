import Observation
import Foundation
import WindowSystem

@Observable
final class AccessibilityStatus {
  private static let pollInterval = Duration.seconds(1)

  private(set) var isGranted = AccessibilityPermission.isGranted
  @ObservationIgnored private var pollTask: Task<Void, Never>?

  func startPolling() {
    stopPolling()
    isGranted = AccessibilityPermission.isGranted
    pollTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: Self.pollInterval)
        self?.isGranted = AccessibilityPermission.isGranted
      }
    }
  }

  func stopPolling() {
    pollTask?.cancel()
    pollTask = nil
  }
}
