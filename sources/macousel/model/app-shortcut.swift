import WindowSystem

struct AppShortcut: Codable, Equatable, Identifiable {
  var bundleIdentifier: String
  var hotkey: Hotkey

  var id: String { bundleIdentifier }
}
