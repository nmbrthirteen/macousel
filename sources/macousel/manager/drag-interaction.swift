import CoreGraphics
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
  private let source: any WindowSource
  private let presenter: LayoutPresenter
  private let pointer: any PointerDevice
  private var drag: Drag?

  init(
    state: TilingState, source: any WindowSource, presenter: LayoutPresenter,
    pointer: any PointerDevice
  ) {
    self.state = state
    self.source = source
    self.presenter = presenter
    self.pointer = pointer
  }

  var isActive: Bool { drag != nil }

  func start() {
    pointer.startObservingPrimaryRelease { [weak self] in self?.finish() }
  }

  func stop() {
    pointer.stopObservingPrimaryRelease()
    cancel()
  }

  func windowChanged(_ window: CGWindowID) {
    guard drag == nil, pointer.isPrimaryButtonDown, presenter.isSettled,
      state.activeKey(containing: WindowID(window)) != nil,
      let requested = presenter.requestedFrame(for: window),
      let actual = source.window(window)?.frame,
      !actual.isClose(to: requested, within: Self.frameTolerance),
      actual.insetBy(dx: -Self.grabMargin, dy: -Self.grabMargin).contains(pointer.location)
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
      let actual = source.window(drag.window)?.frame
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
    let pointerX = pointer.location.x
    let remainingColumns = Set(layout.placements.filter { $0.window != window }.map(\.column))
    let columnsLeftOfPointer = remainingColumns.filter { column in
      layout.placements.first { $0.column == column }.map { $0.frame.midX < pointerX } ?? false
    }
    state.workspaces[key]?.strip.move(window, toColumn: columnsLeftOfPointer.count)
  }
}
