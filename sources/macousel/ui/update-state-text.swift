extension UpdateState {
  var statusText: String {
    switch self {
    case .idle: "No update check yet"
    case .checking: "Checking for updates…"
    case .upToDate: "Macousel is up to date"
    case .available(let release): "Version \(release.version) is available"
    case .downloading: "Downloading the update…"
    case .installing: "Installing the update…"
    case .failed(let message): message
    }
  }
}
