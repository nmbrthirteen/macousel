enum UpdateState: Equatable {
  case idle
  case checking
  case upToDate
  case available(Release)
  case downloading
  case installing
  case failed(String)

  var isInstalling: Bool {
    self == .downloading || self == .installing
  }

  var isBusy: Bool {
    self == .checking || isInstalling
  }
}
