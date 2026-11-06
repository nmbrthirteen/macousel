import Observation

// Walks someone through granting Accessibility: opens the right pane, keeps a helper beside
// System Settings, and finishes on its own when macOS reports the grant.
@Observable
final class AccessibilityGuide {
  // The trust notification can be missed or arrive before the value changes.
  static let pollInterval = Duration.seconds(1)

  enum Phase: Equatable {
    case idle, guiding, staleGrant, granted
  }

  struct Dependencies {
    var isGranted: () -> Bool
    var wasGrantedToAnotherBuild: () -> Bool
    var openSettings: () -> Void
    var resetGrant: () async -> Bool
    var showHelper: () -> Void
    var hideHelper: () -> Void
    var bringToFront: () -> Void
    var watchTrust: (_ onChange: (() -> Void)?) -> Void
    var sleep: (Duration) async throws -> Void
  }

  private(set) var phase: Phase = .idle
  @ObservationIgnored var onGranted: (() -> Void)?
  @ObservationIgnored private let dependencies: Dependencies
  @ObservationIgnored private var poll: Task<Void, Never>?

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  func begin() {
    if dependencies.isGranted() {
      finish()
    } else if dependencies.wasGrantedToAnotherBuild() {
      phase = .staleGrant
    } else {
      guide()
    }
  }

  func fixStaleGrant() async {
    guard phase == .staleGrant else { return }
    _ = await dependencies.resetGrant()
    guide()
  }

  func cancel() {
    stopWatching()
    dependencies.hideHelper()
    phase = .idle
  }

  private func guide() {
    phase = .guiding
    dependencies.openSettings()
    dependencies.showHelper()
    dependencies.watchTrust { [weak self] in self?.check() }
    poll?.cancel()
    poll = Task { [weak self, dependencies] in
      while !Task.isCancelled {
        try? await dependencies.sleep(Self.pollInterval)
        guard !Task.isCancelled else { return }
        self?.check()
      }
    }
  }

  private func check() {
    guard phase == .guiding, dependencies.isGranted() else { return }
    finish()
  }

  private func finish() {
    stopWatching()
    dependencies.hideHelper()
    let wasGuiding = phase == .guiding
    phase = .granted
    if wasGuiding { dependencies.bringToFront() }
    onGranted?()
  }

  private func stopWatching() {
    dependencies.watchTrust(nil)
    poll?.cancel()
    poll = nil
  }
}
