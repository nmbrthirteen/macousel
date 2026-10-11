import AppKit

enum LicenseFolder {
  static func open(bundle: Bundle = .main) {
    guard let folder = bundle.resourceURL else { return }
    NSWorkspace.shared.open(folder)
  }
}
