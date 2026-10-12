import CoreGraphics
import StripCore
import WindowSystem

final class EngineDrag {
  private struct Press {
    var window: WindowID
    var columns: EngineColumns
    var targeting: EngineDropTargeting
    var preview: EngineDropPreview

    var rawWindow: CGWindowID { window.rawValue }

    func target(at point: CGPoint) -> DropTarget {
      targeting.target(dragging: window, at: point)
    }

    func previewFrame(at point: CGPoint) -> CGRect? {
      preview.frame(for: target(at: point), dragging: window) ?? columns.frame(of: window)
    }
  }

  private let pointer: any PointerDevice
  private let host: any OverlayHost
  private let world: EngineWorld
  private let displays: () -> [Display]
  private let reorder: EngineReorder
  private let settler: EngineSettler
  private let isSuppressed: () -> Bool
  private let poller: DragPoller
  private let log = DragLog()
  private var phase = DragPhase.idle
  private var press: Press?
  private var settling: Task<Void, Never>?

  init(
    pointer: any PointerDevice, clock: any AnimationClock, host: any OverlayHost,
    world: EngineWorld, displays: @escaping () -> [Display], reorder: EngineReorder,
    settler: EngineSettler, isSuppressed: @escaping () -> Bool
  ) {
    self.pointer = pointer
    self.host = host
    self.world = world
    self.displays = displays
    self.reorder = reorder
    self.settler = settler
    self.isSuppressed = isSuppressed
    poller = DragPoller(clock: clock)
  }

  var isSettling: Bool { settling != nil }

  func start() {
    pointer.startObservingPrimaryButton { [weak self] event in self?.handle(event) }
  }

  func stop() {
    pointer.stopObservingPrimaryButton()
    poller.stop()
    settling?.cancel()
    settling = nil
    endLiveDrag()
    phase = .idle
    press = nil
  }

  private func handle(_ event: PrimaryButtonEvent) {
    switch event {
    case .pressed(let point): pressed(at: point)
    case .dragged: dragged(noticedBy: .draggedEvent)
    case .released: released()
    }
  }

  private func pressed(at point: CGPoint) {
    phase = .idle
    press = nil
    poller.stop()
    guard settling == nil, !reorder.isRunning, !isSuppressed(),
      let window = pointer.windowID(at: point), let tracked = trackedPress(of: window),
      let baseline = pointer.serverBounds(of: window) ?? tracked.columns.frame(of: tracked.window)
    else { return }
    log.pressed(window, isTiled: true)
    press = tracked
    phase = .candidate(DragCandidate(window: window, requested: baseline, baseline: baseline))
    poller.start { [weak self] in self?.polled() ?? false }
  }

  private func trackedPress(of window: CGWindowID) -> Press? {
    guard let snapshot = world.snapshot, let display = snapshot.display(in: displays()) else {
      return nil
    }
    let columns = snapshot.tiledColumns
    let id = WindowID(window)
    guard columns.position(of: id) != nil else { return nil }
    let viewport = display.visibleFrame
    return Press(
      window: id, columns: columns,
      targeting: EngineDropTargeting(columns: columns, viewport: viewport),
      preview: EngineDropPreview(columns: columns, viewport: viewport))
  }

  private func polled() -> Bool {
    guard pointer.isPrimaryButtonDown else {
      released()
      return false
    }
    dragged(noticedBy: .poll)
    return isPressInProgress
  }

  private var isPressInProgress: Bool {
    switch phase {
    case .idle: false
    case .candidate, .live, .cancelled: true
    }
  }

  private func dragged(noticedBy notice: DragNotice) {
    switch phase {
    case .candidate(let candidate): recognise(candidate, noticedBy: notice)
    case .live: showPreview()
    default: break
    }
  }

  private func recognise(_ candidate: DragCandidate, noticedBy notice: DragNotice) {
    guard let actual = pointer.serverBounds(of: candidate.window),
      !actual.isClose(to: candidate.baseline, within: DragResize.tolerance)
    else { return }
    let resized = DragResize.hasResized(from: candidate.baseline, to: actual)
    let kind: LiveDrag.Kind = resized ? .resize : .move
    log.recognised(candidate.window, as: kind, noticedBy: notice)
    guard kind == .move else {
      poller.stop()
      phase = .idle
      press = nil
      return
    }
    phase = .live(
      LiveDrag(window: candidate.window, baseline: candidate.baseline, kind: .move))
    pointer.startObservingEscape { [weak self] in self?.escaped() }
    showPreview()
  }

  private func showPreview() {
    if let press, let frame = press.previewFrame(at: pointer.location) {
      host.showDropPreview(at: frame)
    } else {
      host.hideDropPreview()
    }
  }

  private func escaped() {
    guard case .live(let drag) = phase else { return }
    phase = .cancelled(drag.window)
    endLiveDrag()
    log.ended(drag.window, as: .cancelled)
  }

  private func released() {
    poller.stop()
    let ended = phase
    phase = .idle
    guard case .live(let drag) = ended, let press else { return }
    endLiveDrag()
    self.press = nil
    let location = pointer.location
    log.released(
      drag.window, at: location, rowsPerColumn: press.columns.windowIDs.map(\.count))
    let target = press.target(at: location)
    guard target != .nowhere else {
      log.ended(drag.window, as: .returnedToSlot)
      return
    }
    settling = Task { [weak self] in await self?.settleAndMove(press, to: target) }
  }

  private func endLiveDrag() {
    host.hideDropPreview()
    pointer.stopObservingEscape()
  }

  private func settleAndMove(_ press: Press, to target: DropTarget) async {
    defer { settling = nil }
    guard await settler.settles(on: press.columns.windowIDs) else {
      log.unsettled(press.rawWindow)
      return
    }
    guard await reorder.move(press.window, to: target) != nil else {
      log.ended(press.rawWindow, as: .returnedToSlot)
      return
    }
    world.refresh()
    log.ended(press.rawWindow, as: Self.branch(for: target))
  }

  private static func branch(for target: DropTarget) -> DragBranch {
    switch target {
    case .nowhere: .returnedToSlot
    case .stack(_, let side): .stacked(above: side == .above)
    case .column(let position): .reordered(column: position + 1)
    }
  }
}
