struct EngineConfigRules {
  static let catchAllName = "all"

  let preferences: Preferences

  private var gaps: EngineConfigGaps {
    EngineConfigGaps(innerGap: preferences.layout.innerGap, outerGap: preferences.layout.outerGap)
  }

  var lines: [String] {
    var lines = catchAll
    var used: Set<String> = [Self.catchAllName]
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
