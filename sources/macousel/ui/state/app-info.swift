import AppKit

struct AppInfo {
  let name: String
  let version: String
  let icon: NSImage

  init(bundle: Bundle = .main) {
    name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Macousel"
    version = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
      .map { "Version \($0)" } ?? "Development build"
    icon = NSApplication.shared.applicationIconImage
  }
}
