struct EngineConfigDecorations {
  static let borderColor = "#0A84FF"

  let preferences: Preferences

  var dimOpacity: String {
    guard preferences.dimsInactiveWindows else { return "0.0" }
    return TomlNumber.decimal(-min(max(preferences.dimAmount, 0), 1))
  }

  var lines: [String] {
    [
      "[decorations]",
      "workspace_menu_status = false",
      "workspace_popup_status = false",
      "",
      "[decorations.menu.descriptor]",
      "style = \"hidden\"",
      "",
      "[decorations.active.border]",
      "enabled = \(preferences.showsFocusBorder)",
      "color = \(TomlString.quoted(Self.borderColor))",
      "width = \(TomlNumber.decimal(preferences.focusBorderWidth))",
      "radius = \"auto\"",
      "",
      "[decorations.inactive.dim]",
      "opacity = \(dimOpacity)",
      "",
      "[restore]",
      "enabled = \(preferences.restoresSession)",
    ]
  }
}
