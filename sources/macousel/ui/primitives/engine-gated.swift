extension EngineFeature {
  // Rows show this as their description and turn off while the engine lacks the feature.
  func unavailableCaption(for engine: WindowEngine) -> String? {
    isSupported(by: engine) ? nil : unavailableCaption
  }
}
