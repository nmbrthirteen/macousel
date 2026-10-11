import Foundation

struct InstallLocationCheck {
  private static let translocationMarker = "/AppTranslocation/"
  private static let diskImagePrefix = "/Volumes/"

  let bundleURL: URL
  let homeDirectory: URL

  var check: SetupCheck {
    SetupCheck(
      id: "install-location",
      passingTitle: "Macousel runs from a stable location",
      attentionTitle: "Macousel runs from a temporary location",
      effect: "macOS ties the Accessibility permission to the app's location.",
      location: "Finder, by moving Macousel to the Applications folder and opening it again",
      isPassing: !isTemporaryLocation
    )
  }

  private var isTemporaryLocation: Bool {
    let path = bundleURL.standardizedFileURL.path
    let downloads = homeDirectory.appendingPathComponent("Downloads").standardizedFileURL.path
    return path.contains(Self.translocationMarker) || path.hasPrefix(Self.diskImagePrefix)
      || path.hasPrefix(downloads + "/")
  }
}
