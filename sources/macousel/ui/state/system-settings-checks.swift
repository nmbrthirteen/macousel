struct SystemSettingsChecks {
  let readers: SystemDefaultsReaders

  var all: [SetupCheck] {
    [separateSpaces, fixedSpaces, edgeTiling, optionDragTiling, stageManager]
  }

  var separateSpaces: SetupCheck {
    SetupCheck(
      id: "separate-spaces",
      passingTitle: "Displays have separate Spaces",
      attentionTitle: "Displays share one Space",
      effect: "Each display needs its own Space to get its own strip.",
      location: "System Settings > Desktop & Dock > Mission Control",
      isPassing: readers.spaces.bool(forKey: "spans-displays") != true
    )
  }

  var fixedSpaces: SetupCheck {
    SetupCheck(
      id: "fixed-spaces",
      passingTitle: "Spaces keep their order",
      attentionTitle: "Spaces rearrange automatically",
      effect: "Rearranged Spaces move strips around.",
      location: "System Settings > Desktop & Dock > Mission Control",
      isPassing: readers.dock.bool(forKey: "mru-spaces") == false
    )
  }

  var edgeTiling: SetupCheck {
    let sideTiling = readers.windowManager.bool(forKey: "EnableTilingByEdgeDrag") ?? true
    let topTiling = readers.windowManager.bool(forKey: "EnableTopTilingByEdgeDrag") ?? true
    return SetupCheck(
      id: "edge-tiling",
      passingTitle: "macOS edge tiling is off",
      attentionTitle: "macOS edge tiling is on",
      effect: "It fights dragging a window to reorder columns.",
      location: "System Settings > Desktop & Dock > Windows",
      isPassing: !sideTiling && !topTiling
    )
  }

  var optionDragTiling: SetupCheck {
    SetupCheck(
      id: "option-drag-tiling",
      passingTitle: "Option-drag tiling is off",
      attentionTitle: "Option-drag tiling is on",
      effect: "Holding Option while dragging a window tiles it and fights column dragging.",
      location: "System Settings > Desktop & Dock > Windows",
      isPassing: readers.windowManager.bool(forKey: "EnableTilingOptionAccelerator") == false
    )
  }

  var stageManager: SetupCheck {
    SetupCheck(
      id: "stage-manager",
      passingTitle: "Stage Manager is off",
      attentionTitle: "Stage Manager is on",
      effect: "It groups and hides windows that Macousel places.",
      location: "System Settings > Desktop & Dock > Windows",
      isPassing: readers.windowManager.bool(forKey: "GloballyEnabled") != true
    )
  }
}
