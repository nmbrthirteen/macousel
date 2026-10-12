import StripCore
import WindowSystem

final class EngineOverview {
  private let host: any OverlayHost
  private let displays: () -> [Display]
  private let reorder: EngineReorder
  private var session: (cursor: ColumnCursor, snapshot: EngineSnapshot)?

  init(host: any OverlayHost, displays: @escaping () -> [Display], reorder: EngineReorder) {
    self.host = host
    self.displays = displays
    self.reorder = reorder
    host.onOverviewSelect = { [weak self] window in self?.choose(window) }
    host.onOverviewKey = { [weak self] key in self?.handle(key) }
    host.onOverviewDismiss = { [weak self] in self?.close() }
    host.onOverviewMove = { [weak self] window, target in self?.drop(window, on: target) }
  }

  var isOpen: Bool { session != nil }

  func toggle(with snapshot: EngineSnapshot?) {
    if isOpen { close() } else if let snapshot { _ = present(snapshot, selecting: nil) }
  }

  func close() {
    guard session != nil else { return }
    session = nil
    host.hideOverview()
  }

  func refresh(with snapshot: EngineSnapshot) {
    guard let current = session, !reorder.isRunning else { return }
    if !present(snapshot, selecting: current.cursor.window) { close() }
  }

  private func present(_ snapshot: EngineSnapshot, selecting preferred: WindowID?) -> Bool {
    guard let display = snapshot.display(in: displays()),
      var content = EngineOverviewBuilder(snapshot: snapshot, displayFrame: display.frame).build()
    else { return false }
    let columns = snapshot.tiledColumns
    let wanted = preferred.flatMap { id in columns.position(of: id) == nil ? nil : id }
      ?? content.selection
    let cursor = ColumnCursor(columns: columns.windowIDs, selecting: wanted)
    content.selection = cursor.window
    session = (cursor, snapshot)
    host.showOverview(content, on: display.frame)
    return true
  }

  private func handle(_ key: OverviewKey) {
    guard var current = session else { return }
    switch key {
    case .move(let direction): current.cursor.move(direction)
    case .jump(let place): current.cursor.jump(toPlace: place)
    case .confirm:
      if let window = current.cursor.window { choose(window) }
      return
    case .dismiss:
      close()
      return
    case .moveWindow, .moveWindowToPlace:
      moveSelection(with: key)
      return
    case .widen, .narrow:
      return
    }
    _ = present(current.snapshot, selecting: current.cursor.window)
  }

  private func moveSelection(with key: OverviewKey) {
    guard let current = session, let window = current.cursor.window,
      let move = EngineKeyMove(key: key, window: window, columns: current.snapshot.tiledColumns)
    else { return }
    Task { [weak self] in
      let outcome: EngineReorderOutcome?
      switch move {
      case .drop(let target): outcome = await self?.reorder.move(window, to: target)
      case .shift(let direction): outcome = await self?.reorder.shift(window, toward: direction)
      }
      self?.finishMove(outcome, selecting: window)
    }
  }

  private func drop(_ window: WindowID, on target: DropTarget) {
    Task { [weak self] in
      let outcome = await self?.reorder.move(window, to: target)
      self?.finishMove(outcome, selecting: window)
    }
  }

  private func finishMove(_ outcome: EngineReorderOutcome?, selecting window: WindowID) {
    guard isOpen, let snapshot = outcome?.snapshot else { return }
    if !present(snapshot, selecting: window) { close() }
  }

  private func choose(_ window: WindowID) {
    guard isOpen else { return }
    close()
    Task { [weak self] in await self?.reorder.focus(window) }
  }
}
