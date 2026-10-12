import CoreGraphics
import StripCore
import WindowSystem

final class EngineDrag {
  static let longPress = Duration.milliseconds(4500)

  private struct Press {
    var window: WindowID
    var point: CGPoint
    var pressedAt: ContinuousClock.Instant
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
  private let clock: any AnimationClock
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
  private var settleToken = 0

  init(
    pointer: any PointerDevice, clock: any AnimationClock, host: any OverlayHost,
    world: EngineWorld, displays: @escaping () -> [Display], reorder: EngineReorder,
    settler: EngineSettler, isSuppressed: @escaping () -> Bool
  ) {
    self.pointer = pointer
    self.clock = clock
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
    if let reason = busyReason {
      log.ignoredPress(reason: reason)
      return
    }
    guard !isSuppressed(), let window = pointer.windowID(at: point),
      let tracked = trackedPress(of: window, at: point),
      let baseline = pointer.serverBounds(of: window) ?? tracked.columns.frame(of: tracked.window)
    else { return }
    log.pressed(window, isTiled: true)
    press = tracked
    phase = .candidate(DragCandidate(window: window, requested: baseline, baseline: baseline))
    poller.start { [weak self] in self?.polled() ?? false }
  }

  private var busyReason: String? {
    if settling != nil { return "a drop is settling" }
    if reorder.isRunning { return "a reorder is running" }
    return nil
  }

  private func trackedPress(of window: CGWindowID, at point: CGPoint) -> Press? {
    guard let snapshot = world.snapshot, let display = snapshot.display(in: displays()) else {
      return nil
    }
    let columns = snapshot.tiledColumns
    let id = WindowID(window)
    guard columns.position(of: id) != nil else { return nil }
    let viewport = display.visibleFrame
    return Press(
      window: id, point: point, pressedAt: clock.now, columns: columns,
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
    guard let origin = press?.point, hasTravelled(from: origin),
      let actual = pointer.serverBounds(of: candidate.window),
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

  private func hasTravelled(from origin: CGPoint) -> Bool {
    let location = pointer.location
    return hypot(location.x - origin.x, location.y - origin.y) > DragResize.tolerance
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
    guard let press else { return }
    switch ended {
    case .live(let drag): finish(drag, press: press)
    case .cancelled: snapIfLong(press)
    default: break
    }
  }

  private func finish(_ drag: LiveDrag, press: Press) {
    endLiveDrag()
    self.press = nil
    let location = pointer.location
    log.released(
      drag.window, at: location, rowsPerColumn: press.columns.windowIDs.map(\.count))
    let target = press.target(at: location)
    guard target != .nowhere else {
      log.ended(drag.window, as: .returnedToSlot)
      snapIfLong(press)
      return
    }
    track { engine in await engine.settleAndMove(press, to: target) }
  }

  private func snapIfLong(_ press: Press) {
    self.press = nil
    guard clock.now - press.pressedAt > Self.longPress else { return }
    log.snapped(press.rawWindow, reason: "long drag ended without a move")
    track { engine in await engine.settler.snap() }
  }

  private func track(_ work: @escaping (EngineDrag) async -> Void) {
    settleToken += 1
    let token = settleToken
    settling = Task { [weak self] in
      guard let self else { return }
      await work(self)
      finishSettling(token)
    }
  }

  private func finishSettling(_ token: Int) {
    guard !Task.isCancelled, settleToken == token else { return }
    settling = nil
  }

  private func endLiveDrag() {
    host.hideDropPreview()
    pointer.stopObservingEscape()
  }

  private func settleAndMove(_ press: Press, to target: DropTarget) async {
    guard await settledAfterSnap(press) else { return }
    let outcome = await reorder.move(press.window, to: target)
    guard !Task.isCancelled else { return }
    conclude(outcome, press: press, target: target)
  }

  private func settledAfterSnap(_ press: Press) async -> Bool {
    let expected = press.columns.windowIDs
    if await settler.settles(on: expected) { return !Task.isCancelled }
    guard !Task.isCancelled else { return false }
    log.snapped(press.rawWindow, reason: "structure did not settle")
    await settler.snap()
    guard !Task.isCancelled else { return false }
    if await settler.settles(on: expected) { return !Task.isCancelled }
    if !Task.isCancelled { log.unsettled(press.rawWindow) }
    return false
  }

  private func conclude(_ outcome: EngineReorderOutcome, press: Press, target: DropTarget) {
    let window = press.rawWindow
    switch outcome {
    case .completed:
      world.refresh()
      log.ended(window, as: Self.branch(for: target))
    case .aborted(let step, _):
      world.refresh()
      log.aborted(window, step: step)
    case .nothingToDo: log.skipped(window, reason: "nothing to move")
    case .busy: log.skipped(window, reason: "another reorder was running")
    case .unavailable: log.skipped(window, reason: "the engine did not answer")
    }
  }

  private static func branch(for target: DropTarget) -> DragBranch {
    switch target {
    case .nowhere: .returnedToSlot
    case .stack(_, let side): .stacked(above: side == .above)
    case .column(let position): .reordered(column: position + 1)
    }
  }
}
