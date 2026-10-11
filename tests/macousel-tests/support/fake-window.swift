import CoreGraphics

@testable import Macousel

@MainActor
final class FakeWindow: WindowHandle {
  let id: CGWindowID
  let pid: pid_t
  let bundleIdentifier: String?
  let appName: String
  var title: String {
    get {
      titleReadCount += 1
      return storedTitle
    }
    set { storedTitle = newValue }
  }
  var frame: CGRect? {
    get {
      frameReadCount += 1
      return storedFrame
    }
    set { storedFrame = newValue }
  }
  var serverFrame: CGRect? { storedFrame }
  var isTileable: Bool {
    get {
      tileableReadCount += 1
      return storedTileable
    }
    set { storedTileable = newValue }
  }
  var isFullScreen: Bool {
    get {
      fullScreenReadCount += 1
      return storedFullScreen
    }
    set { storedFullScreen = newValue }
  }
  var timesOutReads = false
  var sequence: EventSequence?
  var onFocus: ((FakeWindow) -> Void)?
  var onComesForward: ((FakeWindow) -> Void)?
  private(set) var framesSet: [CGRect] = []
  private(set) var focusCount = 0
  private(set) var nonRaisingFocusCount = 0
  private(set) var raiseCount = 0
  private(set) var titleReadCount = 0
  private(set) var fullScreenReadCount = 0
  private(set) var frameReadCount = 0
  private(set) var tileableReadCount = 0
  private var storedFrame: CGRect?
  private var storedFullScreen = false
  private var storedTileable = true
  private var storedTitle: String

  init(id: CGWindowID, app: FakeApp, title: String, frame: CGRect) {
    self.id = id
    pid = app.pid
    bundleIdentifier = app.bundleIdentifier
    appName = app.name
    storedTitle = title
    storedFrame = frame
  }

  func setFrame(_ frame: CGRect) {
    framesSet.append(frame)
    storedFrame = frame
  }

  var raisingFocusCount: Int { focusCount - nonRaisingFocusCount }

  func focus(raising: Bool) {
    focusCount += 1
    sequence?.record(.focused(id))
    if raising {
      onComesForward?(self)
    } else {
      nonRaisingFocusCount += 1
    }
    onFocus?(self)
  }

  func raise() {
    raiseCount += 1
    onComesForward?(self)
  }
}
