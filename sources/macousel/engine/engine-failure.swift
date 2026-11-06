import Foundation

enum EngineFailure: Equatable {
  case notBundled, standaloneRunning, orphanRunning, configUnwritable, launchFailed
  case restartedTooOften

  var message: String {
    switch self {
    case .notBundled: "This build has no engine. Reinstall Macousel or switch to the built-in engine in Settings > General."
    case .standaloneRunning:
      "Paneru is already running on this Mac. Quit it, since two window managers would both move your windows. Then choose Resume tiling."
    case .orphanRunning:
      "An engine from an earlier run did not quit. Quit any other copy of Macousel, then choose Resume tiling."
    case .configUnwritable: "Macousel could not write the engine configuration. Check the disk space and permissions. Then choose Resume tiling."
    case .launchFailed:
      "The engine could not start. Check the log in \(Self.logPath), then choose Resume tiling."
    case .restartedTooOften:
      "The engine stopped \(EngineRestartPolicy.maximumRestarts) times in a minute, so Macousel gave up. Check the log, then choose Resume tiling."
    }
  }

  private static var logPath: String {
    (EnginePaths.system().log.path as NSString).abbreviatingWithTildeInPath
  }
}
