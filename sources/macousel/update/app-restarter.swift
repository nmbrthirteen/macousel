import AppKit

struct AppRestarter {
  var bundleURL = Bundle.main.bundleURL

  func restart() throws {
    try AppRelauncher().start(opening: bundleURL)
    NSApp.terminate(nil)
  }
}
