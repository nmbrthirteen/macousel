enum EngineFailure: Equatable {
  case notBundled, standaloneRunning, configUnwritable, launchFailed, restartedTooOften

  var message: String {
    switch self {
    case .notBundled: "The engine is not bundled in this build."
    case .standaloneRunning:
      "Paneru is already running on this Mac. Quit it, since two window managers would both move your windows."
    case .configUnwritable: "Macousel could not write the engine configuration. Check the disk and try again."
    case .launchFailed: "The engine could not start. The log is in ~/Library/Logs/Macousel/engine.log."
    case .restartedTooOften:
      "The engine stopped three times in a minute, so Macousel gave up. Choose Resume tiling to try again."
    }
  }
}
