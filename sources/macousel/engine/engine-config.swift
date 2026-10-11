struct EngineConfig {
  static let header = "# Written by Macousel. Changes made here are overwritten."

  let preferences: Preferences
  var includesBindings = true

  var text: String {
    let gaps = EngineConfigGaps(
      innerGap: preferences.layout.innerGap, outerGap: preferences.layout.outerGap)
    var sections = [
      [Self.header],
      EngineConfigOptions(preferences: preferences).lines,
      gaps.paddingLines,
      EngineConfigSwipe(preferences: preferences).lines,
      EngineConfigDecorations(preferences: preferences).lines,
      EngineConfigRules(preferences: preferences).lines,
    ]
    sections.append(
      includesBindings ? EngineConfigBindings(shortcuts: preferences.shortcuts).lines : ["[bindings]"])
    return sections.map { $0.joined(separator: "\n") }.joined(separator: "\n\n") + "\n"
  }
}
