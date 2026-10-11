enum EngineRunState: Equatable {
  case stopped, starting, running, waitingToRestart, needsPermission
  case failed(EngineFailure)

  var failure: EngineFailure? {
    if case .failed(let failure) = self { failure } else { nil }
  }

  var description: String {
    switch self {
    case .stopped: "stopped"
    case .starting: "starting"
    case .running: "running"
    case .waitingToRestart: "waiting to restart"
    case .needsPermission: "needs Accessibility access"
    case .failed(let failure): "failed (\(failure))"
    }
  }
}
