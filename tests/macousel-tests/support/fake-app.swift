import Foundation

struct FakeApp {
  var pid: pid_t
  var bundleIdentifier: String
  var name: String

  static let editor = FakeApp(pid: 100, bundleIdentifier: "test.editor", name: "Editor")
  static let browser = FakeApp(pid: 200, bundleIdentifier: "test.browser", name: "Browser")
  static let floater = FakeApp(pid: 400, bundleIdentifier: "test.floater", name: "Floater")
  static let terminal = FakeApp(pid: 300, bundleIdentifier: "test.terminal", name: "Terminal")
}
