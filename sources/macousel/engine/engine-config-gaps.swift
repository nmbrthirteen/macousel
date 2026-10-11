struct EngineConfigGaps {
  let innerGap: Double
  let outerGap: Double

  var windowInset: Int { TomlNumber.integer(innerGap / 2) }

  var edgePadding: Int { max(TomlNumber.integer(outerGap) - windowInset, 0) }

  var paddingLines: [String] {
    [
      "[padding]",
      "top = \(edgePadding)",
      "bottom = \(edgePadding)",
      "left = \(edgePadding)",
      "right = \(edgePadding)",
    ]
  }
}
