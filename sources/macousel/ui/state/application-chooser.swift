import AppKit
import Observation
import UniformTypeIdentifiers

@Observable
final class ApplicationChooser {
  private static let applicationsDirectory = URL(fileURLWithPath: "/Applications")

  private(set) var errorMessage: String?

  func choose(excluding listed: Set<String>) -> String? {
    errorMessage = nil
    let panel = NSOpenPanel()
    panel.directoryURL = Self.applicationsDirectory
    panel.allowedContentTypes = [.applicationBundle]
    panel.allowsMultipleSelection = false
    panel.prompt = "Choose"
    guard panel.runModal() == .OK, let url = panel.url else { return nil }
    let name = FileManager.default.displayName(atPath: url.path)
    guard let identifier = Bundle(url: url)?.bundleIdentifier else {
      errorMessage = "\(name) has no bundle identifier. Choose another app."
      return nil
    }
    guard !listed.contains(identifier) else {
      errorMessage = "\(name) already has a shortcut. Record a new one from its row."
      return nil
    }
    return identifier
  }
}
