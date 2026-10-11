import StripCore
import WindowSystem

final class EngineOverview {
  var onChoose: ((Int) -> Void)?

  private let host: any OverlayHost
  private let displays: () -> [Display]
  private var session: (cursor: ColumnCursor, snapshot: EngineSnapshot)?

  init(host: any OverlayHost, displays: @escaping () -> [Display]) {
    self.host = host
    self.displays = displays
    host.onOverviewSelect = { [weak self] window in self?.choose(window) }
    host.onOverviewKey = { [weak self] key in self?.handle(key) }
    host.onOverviewDismiss = { [weak self] in self?.close() }
  }

  var isOpen: Bool { session != nil }

  func toggle(with snapshot: EngineSnapshot?) {
    if isOpen { close() } else if let snapshot { open(snapshot) }
  }

  func close() {
    guard session != nil else { return }
    session = nil
    host.hideOverview()
  }

  private func open(_ snapshot: EngineSnapshot) {
    guard let display = snapshot.display(in: displays()),
      let content = EngineOverviewBuilder(snapshot: snapshot, displayFrame: display.frame).build()
    else { return }
    let windows = snapshot.tiledWindows.compactMap { EngineWindowID.make($0.windowId) }
    let cursor = ColumnCursor(columns: windows.map { [$0] }, selecting: content.selection)
    session = (cursor, snapshot)
    host.showOverview(content, on: display.frame)
  }

  private func handle(_ key: OverviewKey) {
    guard var current = session, let display = current.snapshot.display(in: displays()) else {
      return
    }
    switch key {
    case .move(let direction): current.cursor.move(direction)
    case .jump(let place): current.cursor.jump(toPlace: place)
    case .confirm:
      if let window = current.cursor.window { choose(window) }
      return
    case .dismiss:
      close()
      return
    case .moveWindow, .moveWindowToPlace, .widen, .narrow:
      return
    }
    session = current
    guard
      var content = EngineOverviewBuilder(snapshot: current.snapshot, displayFrame: display.frame)
        .build()
    else { return }
    content.selection = current.cursor.window
    host.showOverview(content, on: display.frame)
  }

  private func choose(_ window: WindowID) {
    guard let current = session else { return }
    let column = current.snapshot.columnIndex(of: window)
    close()
    if let column { onChoose?(column) }
  }
}
