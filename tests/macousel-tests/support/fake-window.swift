import CoreGraphics

@testable import Macousel

@MainActor
final class FakeWindow: WindowHandle {
  let id: CGWindowID
  let pid: pid_t
  let bundleIdentifier: String?
  let appName: String
  var title: String
  var frame: CGRect?
  var isTileable = true
  var isFullScreen = false
  var onFocus: ((FakeWindow) -> Void)?
  private(set) var framesSet: [CGRect] = []
  private(set) var focusCount = 0

  init(id: CGWindowID, app: FakeApp, title: String, frame: CGRect) {
    self.id = id
    pid = app.pid
    bundleIdentifier = app.bundleIdentifier
    appName = app.name
    self.title = title
    self.frame = frame
  }

  func setFrame(_ frame: CGRect) {
    framesSet.append(frame)
    self.frame = frame
  }

  func focus() {
    focusCount += 1
    onFocus?(self)
  }
}
