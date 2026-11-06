import StripCore
import SwiftUI

@Observable
final class MinimapModel {
  struct Lift: Equatable {
    var cell: WindowID
    var offset: Double
  }

  private(set) var snapshot = MinimapSnapshot.empty
  private(set) var arrangement = MinimapSnapshot.empty
  private(set) var lift: Lift?
  var isShown = false
  private(set) var isPointerInside = false
  private(set) var hoveredWindow: WindowID?

  @ObservationIgnored var isInteractive = false
  @ObservationIgnored var interaction = MinimapInteraction.idle
  @ObservationIgnored var onSelect: (WindowID) -> Void = { _ in }
  @ObservationIgnored var onMove: (WindowID, DropTarget) -> Void = { _, _ in }
  @ObservationIgnored var onVisibilityChange: (Bool) -> Void = { _ in }
  @ObservationIgnored var isHoldingShortcut: () -> Bool = { false }
  @ObservationIgnored let icons = AppIconCache(iconSide: Metrics.Minimap.iconSide)
  @ObservationIgnored private let linger: MinimapLinger

  init(
    now: @escaping () -> ContinuousClock.Instant = { .now },
    schedule: @escaping (Duration, @escaping () -> Void) -> Void = { _, _ in }
  ) {
    linger = MinimapLinger(now: now, schedule: schedule)
    linger.onElapsed = { [weak self] in self?.lingerElapsed() }
  }

  private var isIdle: Bool {
    if case .idle = interaction { return true }
    return false
  }

  func show(_ snapshot: MinimapSnapshot, update: MinimapUpdate) {
    guard snapshot.isRenderable || isShown else { return }
    if snapshot.isRenderable {
      apply(snapshot, update: isShown ? update : .immediate)
    }
    if !isShown { isShown = true }
    restartLinger()
  }

  /// Keeps the last snapshot on screen and lets it fade on the usual linger, so an engine
  /// that briefly reports nothing does not blank the minimap between two good frames.
  func release() {
    guard isShown else {
      hide()
      return
    }
    if !linger.isRunning { restartLinger() }
  }

  func hide() {
    linger.cancel()
    interaction = .idle
    if isShown { isShown = false }
    if isPointerInside { isPointerInside = false }
    if hoveredWindow != nil { hoveredWindow = nil }
    if lift != nil { lift = nil }
    if arrangement != snapshot { arrangement = snapshot }
  }

  func pointerEntered() {
    isPointerInside = true
    linger.cancel()
    guard !isShown, snapshot.isRenderable else { return }
    isShown = true
    onVisibilityChange(true)
  }

  func pointerMoved(to point: CGPoint) {
    let window = MinimapGeometry(snapshot: arrangement).cell(at: point)?.window
    if window != hoveredWindow { hoveredWindow = window }
  }

  func pointerExited() {
    isPointerInside = false
    if hoveredWindow != nil { hoveredWindow = nil }
    if isIdle { restartLinger() }
  }

  func shortcutReleased() {
    guard isShown, isIdle, !isPointerInside else { return }
    restartLinger()
  }

  func apply(_ snapshot: MinimapSnapshot, update: MinimapUpdate) {
    guard snapshot != self.snapshot else { return }
    self.snapshot = snapshot
    guard isIdle, arrangement != snapshot else { return }
    withAnimation(update.animation(response: snapshot.animationResponse)) {
      arrangement = snapshot
    }
  }

  func setArrangement(_ next: MinimapSnapshot, lift: Lift?) {
    let animation = MinimapUpdate.animated.animation(response: snapshot.animationResponse)
    if next != arrangement { withAnimation(animation) { arrangement = next } }
    guard lift != self.lift else { return }
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) { self.lift = lift }
  }

  func finishInteraction(pointerIsInside: Bool) {
    isPointerInside = pointerIsInside
    if arrangement != snapshot { setArrangement(snapshot, lift: nil) }
    if !pointerIsInside { restartLinger() }
  }

  private func restartLinger() {
    linger.restart(after: OverlayTiming.minimapLinger)
  }

  // Held base modifiers keep the minimap up. Asking again when the linger ends also covers
  // a release that the event monitor never saw.
  private func lingerElapsed() {
    guard !isPointerInside, isIdle, isShown else { return }
    guard !isHoldingShortcut() else {
      restartLinger()
      return
    }
    isShown = false
    if hoveredWindow != nil { hoveredWindow = nil }
    onVisibilityChange(false)
  }
}
