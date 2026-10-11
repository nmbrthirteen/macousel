nonisolated enum UpdateInstallError: UserFacingError, Equatable {
  case untrustedDownload
  case unverifiedUpdate
  case downloadFailed
  case unpackFailed
  case missingApp
  case wrongIdentifier
  case notNewer
  case invalidSignature
  case needsApplicationsFolder
  case swapFailed
  case relaunchFailed

  var message: String {
    switch self {
    case .untrustedDownload:
      "The update is not hosted in the Macousel releases on GitHub, so Macousel did not download it. Get the release from the releases page instead."
    case .unverifiedUpdate:
      "This update could not be verified, so it was not installed. Download it from the releases page if you trust it."
    case .downloadFailed:
      "The download failed. Check your internet connection and try again."
    case .unpackFailed:
      "Macousel could not unpack the download. Try again."
    case .missingApp:
      "The download did not contain Macousel.app. Get the release from the releases page instead."
    case .wrongIdentifier:
      "The download is a different app than Macousel. Get the release from the releases page instead."
    case .notNewer:
      "The download is not newer than the version you have. Check for updates again."
    case .invalidSignature:
      "The downloaded app failed its signature check. Try again, or get the release from the releases page."
    case .needsApplicationsFolder:
      "Move Macousel to the Applications folder, then update."
    case .swapFailed:
      "Macousel could not replace itself, and the old version is still in place. Quit other copies of Macousel and try again."
    case .relaunchFailed:
      "The update is installed, but Macousel could not restart. Open Macousel again."
    }
  }
}
