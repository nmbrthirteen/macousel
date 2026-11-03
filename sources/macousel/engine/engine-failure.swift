import Foundation

enum EngineFailure: Equatable {
  case notBundled, standaloneRunning, orphanRunning, configUnwritable, launchFailed
  case restartedTooOften

  var message: String {
    switch self {
    case .notBundled: "The engine is not bundled in this build."
    case .standaloneRunning:
      "Paneru is already running on this Mac. Quit it, since two window managers would both move your windows."
    case .orphanRunning:
      "An engine from an earlier run did not quit. Quit any other copy of Macousel, then choose Resume tiling."
    case .configUnwritable: "Macousel could not write the engine configuration. Check the disk and try again."
    case .launchFailed:
      "The engine could not start. The log is in \(Self.logPath)."
    case .restartedTooOften:
      "The engine stopped \(EngineRestartPolicy.maximumRestarts) times in a minute, so Macousel gave up. Choose Resume tiling to try again."
    }
  }

  private static var logPath: String {
    (EnginePaths.system().log.path as NSString).abbreviatingWithTildeInPath
  }
}
