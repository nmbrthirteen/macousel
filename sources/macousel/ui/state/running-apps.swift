import Observation
import AppKit

@Observable
final class RunningApps {
  private(set) var apps: [AppIdentity] = []
  @ObservationIgnored private var observation: Task<Void, Never>?

  func start() {
    refresh()
    observation?.cancel()
    observation = Task { [weak self] in
      let center = NSWorkspace.shared.notificationCenter
      for await _ in center.notifications(named: NSWorkspace.didLaunchApplicationNotification) {
        self?.refresh()
      }
    }
  }

  func stop() {
    observation?.cancel()
    observation = nil
  }

  func excluding(_ identifiers: Set<String>) -> [AppIdentity] {
    apps.filter { !identifiers.contains($0.id) }
  }

  private func refresh() {
    let own = Bundle.main.bundleIdentifier
    apps = NSWorkspace.shared.runningApplications
      .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != own }
      .compactMap(AppIdentity.init(running:))
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }
}
