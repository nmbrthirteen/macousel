nonisolated enum EngineFeature: CaseIterable, Sendable {
  static let unsupportedCaption = "Built-in engine only."
  static let paneruOnlyCaption = "Paneru engine only."

  case perDisplayTiling, displayFollowsPointer, floatingWindowsOnTop, dragPreviews
  case nativeTabGrouping

  func isSupported(by engine: WindowEngine) -> Bool {
    switch (self, engine) {
    case (.nativeTabGrouping, _): engine == .paneru
    case (_, .builtIn): true
    case (.dragPreviews, .paneru): true
    case (_, .paneru): false
    }
  }

  var unavailableCaption: String {
    self == .nativeTabGrouping ? Self.paneruOnlyCaption : Self.unsupportedCaption
  }
}
