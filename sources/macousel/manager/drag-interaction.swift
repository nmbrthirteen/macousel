import AppKit
import StripCore
import WindowSystem

final class DragInteraction {
  private static let frameTolerance: CGFloat = 2
  private static let grabMargin: CGFloat = 12

  private struct Drag {
    var window: CGWindowID
    var startFrame: CGRect
  }

  private let state: TilingState
  private let tracker: WindowTracker
  private let presenter: LayoutPresenter
  private var drag: Drag?
  private var mouseUpMonitor: Any?

  init(state: TilingState, tracker: WindowTracker, presenter: LayoutPresenter) {
    self.state = state
    self.tracker = tracker
    self.presenter = presenter
  }

  var isActive: Bool { drag != nil }

  func start() {
    guard mouseUpMonitor == nil else { return }
    mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
      self?.finish()
    }
  }

  func stop() {
    if let mouseUpMonitor { NSEvent.removeMonitor(mouseUpMonitor) }
    mouseUpMonitor = nil
    cancel()
  }

  func windowChanged(_ window: CGWindowID) {
    guard drag == nil, Pointer.isPrimaryButtonDown, presenter.isSettled,
      state.activeKey(containing: WindowID(window)) != nil,
      let requested = presenter.requestedFrame(for: window),
      let actual = tracker.windows[window]?.frame,
      !actual.isClose(to: requested, within: Self.frameTolerance),
      actual.insetBy(dx: -Self.grabMargin, dy: -Self.grabMargin).contains(Pointer.location)
    else { return }
    drag = Drag(window: window, startFrame: requested)
    presenter.excludedWindow = window
  }

  private func cancel() {
    drag = nil
    presenter.excludedWindow = nil
  }

  private func finish() {
    guard let drag else { return }
    cancel()
    presenter.invalidate(drag.window)
    let window = WindowID(drag.window)
    guard let key = state.activeKey(containing: window),
      let actual = tracker.windows[drag.window]?.frame
    else { return }

    if hasResized(from: drag.startFrame, to: actual) {
      resize(window, in: key, from: drag.startFrame, to: actual)
    } else {
      drop(window, from: key)
    }
    presenter.overlays.refreshTitles()
    presenter.relayout()
  }

  private func hasResized(from start: CGRect, to end: CGRect) -> Bool {
    abs(end.width - start.width) > Self.frameTolerance
      || abs(end.height - start.height) > Self.frameTolerance
  }

  private func resize(
    _ window: WindowID, in key: Workspace.Key, from start: CGRect, to end: CGRect
  ) {
    if abs(end.width - start.width) > Self.frameTolerance {
      state.workspaces[key]?.strip.setFixedWidth(end.width, of: window)
    }
    if abs(end.height - start.height) > Self.frameTolerance,
      let display = state.display(for: key)
    {
      let draggedTopEdge = abs(end.minY - start.minY) > Self.frameTolerance
      state.workspaces[key]?.strip.setHeight(
        end.height, of: window, borrowingFrom: draggedTopEdge ? .above : .below,
        viewportHeight: display.visibleFrame.height, config: state.config)
    }
    state.scrollToFocus(key)
  }

  private func drop(_ window: WindowID, from key: Workspace.Key) {
    let destination = state.pointerKey ?? key
    if destination == key {
      reorder(window, in: key)
    } else {
      state.workspaces[key]?.strip.remove(window)
      state.workspaces[destination]?.strip.insert(window, config: state.config)
      state.scrollToFocus(key)
    }
    state.scrollToFocus(destination)
    state.focusedKey = destination
  }

  private func reorder(_ window: WindowID, in key: Workspace.Key) {
    guard let layout = state.targetLayout(for: key) else { return }
    let pointerX = Pointer.location.x
    let remainingColumns = Set(layout.placements.filter { $0.window != window }.map(\.column))
    let columnsLeftOfPointer = remainingColumns.filter { column in
      layout.placements.first { $0.column == column }.map { $0.frame.midX < pointerX } ?? false
    }
    state.workspaces[key]?.strip.move(window, toColumn: columnsLeftOfPointer.count)
  }
}
