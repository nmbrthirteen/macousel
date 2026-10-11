import CoreGraphics
import StripCore

final class OverviewController {
  private struct Session {
    var cursor: ColumnCursor
    var snapshot: OverviewSnapshot
    var key: Workspace.Key
  }

  var onChoose: (WindowID) -> Void = { _ in }

  private let state: TilingState
  private let source: any WindowSource
  private let host: any OverlayHost
  private let titles: () -> [CGWindowID: String]
  private var session: Session?

  init(
    state: TilingState, source: any WindowSource, host: any OverlayHost,
    titles: @escaping () -> [CGWindowID: String]
  ) {
    self.state = state
    self.source = source
    self.host = host
    self.titles = titles
    host.onOverviewSelect = { [weak self] window in self?.choose(window) }
    host.onOverviewKey = { [weak self] key in self?.handle(key) }
    host.onOverviewDismiss = { [weak self] in self?.close() }
  }

  func toggle() {
    if session == nil { open() } else { close() }
  }

  func open() {
    guard session == nil, let key = state.focusedKey ?? state.pointerKey,
      let strip = state.workspaces[key]?.strip, !strip.isEmpty,
      let snapshot = snapshot(of: strip, in: key)
    else { return }
    session = Session(
      cursor: ColumnCursor(columns: strip.columns.map(\.windows), selecting: strip.focusedWindow),
      snapshot: snapshot, key: key)
    render()
  }

  func close() {
    guard session != nil else { return }
    session = nil
    host.hideOverview()
  }

  func handle(_ key: OverviewKey) {
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
    }
    session = current
    render()
  }

  private func choose(_ window: WindowID) {
    guard session != nil else { return }
    close()
    onChoose(window)
  }

  private func render() {
    guard var current = session, let display = state.display(for: current.key) else { return }
    current.snapshot.selection = current.cursor.window
    session = current
    host.showOverview(current.snapshot, on: display.frame)
  }

  private func snapshot(of strip: Strip, in key: Workspace.Key) -> OverviewSnapshot? {
    guard let display = state.display(for: key), let layout = state.targetLayout(for: key)
    else { return nil }
    let names = titles()
    let columns = strip.columns.enumerated().map { index, column in
      OverviewSnapshot.Column(
        width: Double(layout.placements.first { $0.column == index }?.frame.width ?? 0),
        cards: column.windows.indices.map { row in
          card(for: column, row: row, names: names)
        })
    }
    return OverviewSnapshot(
      columns: columns, stripHeight: display.visibleFrame.height - 2 * state.config.outerGap,
      selection: strip.focusedWindow)
  }

  private func card(for column: Column, row: Int, names: [CGWindowID: String])
    -> OverviewSnapshot.Card
  {
    let window = column.windows[row]
    let handle = source.window(window.rawValue)
    let captured = names[window.rawValue] ?? ""
    let isTabbed = column.display == .tabbed
    let share =
      isTabbed
      ? 1 : column.heightWeights[row] / column.heightWeights.reduce(0, +)
    return OverviewSnapshot.Card(
      window: window, title: captured.isEmpty ? handle?.appName ?? "" : captured,
      bundleIdentifier: handle?.bundleIdentifier, heightShare: share)
  }
}
