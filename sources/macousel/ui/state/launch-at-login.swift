import Observation
import ServiceManagement

@Observable
final class LaunchAtLogin {
  private(set) var isEnabled = SMAppService.mainApp.status == .enabled
  private(set) var errorMessage: String?

  func refresh() {
    isEnabled = SMAppService.mainApp.status == .enabled
  }

  func set(_ enabled: Bool) {
    do {
      if enabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
      errorMessage = nil
    } catch {
      let verb = enabled ? "enable" : "disable"
      errorMessage =
        "Could not \(verb) launch at login: \(error.localizedDescription) Try again from System Settings > General > Login Items."
    }
    refresh()
  }
}
