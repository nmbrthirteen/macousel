nonisolated enum EngineFeature: CaseIterable, Sendable {
  static let unsupportedCaption = "Built-in engine only."

  case perDisplayTiling, displayFollowsPointer, floatingWindowsOnTop, dragPreviews

  func isSupported(by engine: WindowEngine) -> Bool {
    switch engine {
    case .builtIn: true
    case .paneru: self == .dragPreviews
    }
  }
}
