struct EngineConfigRules {
  static let catchAllName = "all"
  static let ownWindowsName = "macousel"
  static let ownBundleIdentifier = "dev.macousel.app"

  let preferences: Preferences

  private var gaps: EngineConfigGaps {
    EngineConfigGaps(innerGap: preferences.layout.innerGap, outerGap: preferences.layout.outerGap)
  }

  var lines: [String] {
    var lines = catchAll + [""] + ownWindows
    var used: Set<String> = [Self.catchAllName, Self.ownWindowsName]
    for rule in preferences.appRules {
      lines += [""] + section(for: rule, name: uniqueName(for: rule, used: &used))
    }
    return lines
  }

  private var catchAll: [String] {
    var lines = [
      "[windows.\(Self.catchAllName)]",
      "title = \".*\"",
      "horizontal_padding = \(gaps.windowInset)",
      "vertical_padding = \(gaps.windowInset)",
    ]
    if !preferences.hasWidthRule {
      lines.append("width = \(TomlNumber.decimal(preferences.layout.defaultWidth))")
    }
    return lines
  }

  // Settings turns Macousel into a regular app while open, which Paneru would otherwise tile.
  private var ownWindows: [String] {
    [
      "[windows.\(Self.ownWindowsName)]",
      "bundle_id = \(TomlString.quoted(Self.ownBundleIdentifier))",
      "title = \".*\"",
      "floating = true",
    ]
  }

  private func section(for rule: AppRule, name: String) -> [String] {
    let header = [
      "[windows.\(name)]",
      "bundle_id = \(TomlString.quoted(rule.bundleIdentifier))",
      "title = \".*\"",
    ]
    switch rule.behavior {
    case .float: return header + ["floating = true"]
    case .width(let fraction): return header + ["width = \(TomlNumber.decimal(fraction))"]
    case .slot(let position): return header + ["index = \(max(position - 1, 0))"]
    }
  }

  private func uniqueName(for rule: AppRule, used: inout Set<String>) -> String {
    let base = "app_" + TomlString.key(from: rule.bundleIdentifier)
    var name = base
    var suffix = 2
    while !used.insert(name).inserted {
      name = "\(base)_\(suffix)"
      suffix += 1
    }
    return name
  }
}
