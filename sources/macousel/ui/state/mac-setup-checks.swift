import Observation
import AppKit
import WindowSystem

@Observable
final class MacSetupChecks {
  private(set) var checks: [SetupCheck] = []
  @ObservationIgnored private var activation: Task<Void, Never>?

  func start() {
    refresh()
    activation?.cancel()
    activation = Task { [weak self] in
      for await _ in NotificationCenter.default.notifications(
        named: NSApplication.didBecomeActiveNotification)
      {
        self?.refresh()
      }
    }
  }

  func stop() {
    activation?.cancel()
    activation = nil
  }

  func refresh() {
    let competitors = CompetingWindowManagers.running()
    checks = [
      accessibilityCheck,
      separateSpacesCheck,
      fixedSpacesCheck,
      edgeTilingCheck,
      stageManagerCheck,
      competitorsCheck(running: competitors),
    ]
  }

  private var accessibilityCheck: SetupCheck {
    let isGranted = AccessibilityPermission.isGranted
    return SetupCheck(
      id: "accessibility",
      passingTitle: "Accessibility access granted",
      attentionTitle: "Accessibility access needed",
      effect: "Without it Macousel cannot move or resize windows.",
      location: "System Settings > Privacy & Security > Accessibility",
      isPassing: isGranted,
      fix: .init(title: "Open System Settings", perform: AccessibilityPermission.openSystemSettings)
    )
  }

  private var separateSpacesCheck: SetupCheck {
    SetupCheck(
      id: "separate-spaces",
      passingTitle: "Displays have separate Spaces",
      attentionTitle: "Displays share one Space",
      effect: "Each display needs its own Space to get its own strip.",
      location: "System Settings > Desktop & Dock > Mission Control",
      isPassing: SystemDefaults.spaces.bool(forKey: "spans-displays") != true
    )
  }

  private var fixedSpacesCheck: SetupCheck {
    SetupCheck(
      id: "fixed-spaces",
      passingTitle: "Spaces keep their order",
      attentionTitle: "Spaces rearrange automatically",
      effect: "Rearranged Spaces move strips around.",
      location: "System Settings > Desktop & Dock > Mission Control",
      isPassing: SystemDefaults.dock.bool(forKey: "mru-spaces") == false
    )
  }

  private var edgeTilingCheck: SetupCheck {
    let sideTiling = SystemDefaults.windowManager.bool(forKey: "EnableTilingByEdgeDrag") ?? true
    let topTiling = SystemDefaults.windowManager.bool(forKey: "EnableTopTilingByEdgeDrag") ?? true
    return SetupCheck(
      id: "edge-tiling",
      passingTitle: "macOS edge tiling is off",
      attentionTitle: "macOS edge tiling is on",
      effect: "It fights dragging a window to reorder columns.",
      location: "System Settings > Desktop & Dock > Windows",
      isPassing: !sideTiling && !topTiling
    )
  }

  private var stageManagerCheck: SetupCheck {
    SetupCheck(
      id: "stage-manager",
      passingTitle: "Stage Manager is off",
      attentionTitle: "Stage Manager is on",
      effect: "It groups and hides windows that Macousel places.",
      location: "System Settings > Desktop & Dock > Windows",
      isPassing: SystemDefaults.windowManager.bool(forKey: "GloballyEnabled") != true
    )
  }

  private func competitorsCheck(running names: [String]) -> SetupCheck {
    SetupCheck(
      id: "competitors",
      passingTitle: "No other window manager is running",
      attentionTitle: "Another window manager is running",
      effect: "Two window managers move the same windows and undo each other.",
      location: "that app, or System Settings > General > Login Items",
      isPassing: names.isEmpty,
      offenders: names
    )
  }
}
