struct EngineConfigOptions {
  let preferences: Preferences

  var lines: [String] {
    var lines = [
      "[options]",
      "focus_follows_mouse = \(preferences.focusFollowsMouse)",
      "mouse_follows_focus = \(preferences.mouseFollowsFocus)",
      "preset_column_widths = \(TomlNumber.array(preferences.layout.presetWidths))",
    ]
    if let speed = preferences.animationSpeed.paneruSpeed {
      lines.append("animation_speed = \(TomlNumber.decimal(speed))")
    }
    lines.append("auto_center = \(preferences.layout.centerMode != .never)")
    return lines
  }
}

extension AnimationSpeed {
  var paneruSpeed: Double? {
    switch self {
    case .off: nil
    case .fast: 20
    case .standard: 14
    case .relaxed: 8
    }
  }
}
