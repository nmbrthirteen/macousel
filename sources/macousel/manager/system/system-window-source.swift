import CoreGraphics
import WindowSystem

final class SystemWindowSource: WindowSource {
  private let tracker: WindowTracker

  init(tracker: WindowTracker) {
    self.tracker = tracker
  }

  var windows: [CGWindowID: any WindowHandle] {
    tracker.windows.mapValues { SystemWindow($0) }
  }

  var onEvent: ((WindowSourceEvent) -> Void)? {
    didSet {
      guard let onEvent else {
        tracker.onEvent = nil
        return
      }
      tracker.onEvent = { onEvent(Self.translate($0)) }
    }
  }

  func window(_ id: CGWindowID) -> (any WindowHandle)? {
    tracker.windows[id].map { SystemWindow($0) }
  }

  func start() {
    tracker.start()
  }

  func stop() {
    tracker.stop()
  }

  func focusedWindow() -> (any WindowHandle)? {
    tracker.focusedWindow().map { SystemWindow($0) }
  }

  private static func translate(_ event: WindowEvent) -> WindowSourceEvent {
    switch event {
    case .created(let window): .created(window.id)
    case .destroyed(let id): .destroyed(id)
    case .focused(let id): .focused(id)
    case .moved(let id): .moved(id)
    case .resized(let id): .resized(id)
    case .minimized(let id): .minimized(id)
    case .restored(let id): .restored(id)
    case .appHidden(let pid): .appHidden(pid)
    case .appShown(let pid): .appShown(pid)
    }
  }
}
