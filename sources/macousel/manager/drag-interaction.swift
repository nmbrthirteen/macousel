import CoreGraphics
import StripCore

final class DragInteraction {
  private let state: TilingState
  private let presenter: LayoutPresenter
  private let pointer: any PointerDevice
  private let planner: DropPlanner
  private let resize: DragResize
  private let log = DragLog()
  private var phase = DragPhase.idle

  init(state: TilingState, presenter: LayoutPresenter, pointer: any PointerDevice) {
    self.state = state
    self.presenter = presenter
    self.pointer = pointer
    planner = DropPlanner(state: state)
    resize = DragResize(state: state)
  }

  var isActive: Bool {
    switch phase {
    case .live, .cancelled: true
    case .idle, .candidate: false
    }
  }

  func start() {
    pointer.startObservingPrimaryButton { [weak self] event in self?.handle(event) }
  }

  func stop() {
    pointer.stopObservingPrimaryButton()
    if case .live = phase { endLiveDrag() }
    phase = .idle
  }

  private func handle(_ event: PrimaryButtonEvent) {
    switch event {
    case .pressed: pressed()
    case .dragged: dragged()
    case .released: released()
    }
  }

  private func pressed() {
    phase = .idle
    guard presenter.isSettled, let window = pointer.windowID(at: pointer.location),
      state.activeKey(containing: WindowID(window)) != nil,
      let requested = presenter.requestedFrame(for: window)
    else { return }
    phase = .candidate(
      DragCandidate(
        window: window, requested: requested,
        baseline: pointer.serverBounds(of: window) ?? requested))
  }

  private func dragged() {
    switch phase {
    case .candidate(let candidate): recognise(candidate)
    case .live(let drag) where drag.kind == .move: showPreview(for: drag)
    default: break
    }
  }

  private func recognise(_ candidate: DragCandidate) {
    let window = candidate.window
    guard presenter.isSettled, state.activeKey(containing: WindowID(window)) != nil,
      let actual = pointer.serverBounds(of: window)
    else { return }
    let reference =
      presenter.requestedFrame(for: window).flatMap { $0 == candidate.requested ? nil : $0 }
      ?? candidate.baseline
    guard !actual.isClose(to: reference, within: DragResize.tolerance) else { return }
    let kind: LiveDrag.Kind = DragResize.hasResized(from: reference, to: actual) ? .resize : .move
    let drag = LiveDrag(window: window, baseline: reference, kind: kind)
    phase = .live(drag)
    presenter.excludedWindow = window
    log.recognised(window, as: kind)
    guard kind == .move else { return }
    pointer.startObservingEscape { [weak self] in self?.escaped() }
    showPreview(for: drag)
  }

  private func showPreview(for drag: LiveDrag) {
    let frame = plan(for: drag)?.previewFrame
    if let frame {
      presenter.overlays.showDropPreview(at: frame)
    } else {
      presenter.overlays.hideDropPreview()
    }
  }

  private func plan(for drag: LiveDrag) -> DropPlan? {
    let window = WindowID(drag.window)
    guard let key = state.activeKey(containing: window) else { return nil }
    return planner.plan(dragging: window, from: key, pointer: pointer.location)
  }

  private func escaped() {
    guard case .live(let drag) = phase, drag.kind == .move else { return }
    phase = .cancelled(drag.window)
    endLiveDrag()
    log.ended(drag.window, as: .cancelled)
    putBack(drag.window)
  }

  private func released() {
    let ended = phase
    phase = .idle
    switch ended {
    case .live(let drag):
      endLiveDrag()
      finish(drag)
    case .cancelled(let window):
      putBack(window)
    case .idle, .candidate:
      break
    }
  }

  private func endLiveDrag() {
    presenter.excludedWindow = nil
    presenter.overlays.hideDropPreview()
    pointer.stopObservingEscape()
  }

  private func putBack(_ window: CGWindowID) {
    presenter.invalidate(window)
    presenter.relayout()
  }

  private func finish(_ drag: LiveDrag) {
    let window = WindowID(drag.window)
    guard let key = state.activeKey(containing: window) else { return }
    let branch: DragBranch
    switch drag.kind {
    case .resize:
      branch = commitResize(drag, of: window, in: key)
    case .move:
      branch = commitMove(of: window, drag: drag)
    }
    log.ended(drag.window, as: branch)
    presenter.invalidate(drag.window)
    presenter.overlays.rereadTitles()
    presenter.relayout()
  }

  private func commitResize(_ drag: LiveDrag, of window: WindowID, in key: Workspace.Key)
    -> DragBranch
  {
    guard let end = pointer.serverBounds(of: drag.window) else { return .returnedToSlot }
    return resize.commit(window, in: key, from: drag.baseline, to: end)
  }

  private func commitMove(of window: WindowID, drag: LiveDrag) -> DragBranch {
    guard let plan = plan(for: drag) else { return .returnedToSlot }
    planner.commit(plan)
    switch plan.target {
    case .nowhere:
      return plan.movesToAnotherDisplay ? .movedToDisplay : .returnedToSlot
    case .stack(_, let side):
      return .stacked(above: side == .above)
    case .column:
      let column = plan.strips[plan.destination]?.columnIndex(of: window) ?? 0
      return .reordered(column: column + 1)
    }
  }
}
