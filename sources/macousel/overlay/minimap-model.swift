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

  @ObservationIgnored var isInteractive = false
  @ObservationIgnored var interaction = MinimapInteraction.idle
  @ObservationIgnored var onSelect: (WindowID) -> Void = { _ in }
  @ObservationIgnored var onMove: (WindowID, DropTarget) -> Void = { _, _ in }
  @ObservationIgnored var onVisibilityChange: (Bool) -> Void = { _ in }
  @ObservationIgnored let icons = MinimapIconCache()
  @ObservationIgnored private let schedule: (Duration, @escaping () -> Void) -> Void
  @ObservationIgnored private var lingerGeneration = 0

  init(schedule: @escaping (Duration, @escaping () -> Void) -> Void = { _, _ in }) {
    self.schedule = schedule
  }

  private var isIdle: Bool {
    if case .idle = interaction { return true }
    return false
  }

  func show(_ snapshot: MinimapSnapshot, update: MinimapUpdate) {
    apply(snapshot, update: isShown ? update : .immediate)
    isShown = true
    restartLinger()
  }

  func hide() {
    lingerGeneration += 1
    interaction = .idle
    isShown = false
    isPointerInside = false
    lift = nil
    arrangement = snapshot
  }

  func pointerEntered() {
    isPointerInside = true
    lingerGeneration += 1
    guard !isShown else { return }
    isShown = true
    onVisibilityChange(true)
  }

  func pointerExited() {
    isPointerInside = false
    if isIdle { restartLinger() }
  }

  func apply(_ snapshot: MinimapSnapshot, update: MinimapUpdate) {
    self.snapshot = snapshot
    guard isIdle else { return }
    withAnimation(update.animation(response: snapshot.animationResponse)) {
      arrangement = snapshot
    }
  }

  func setArrangement(_ next: MinimapSnapshot, lift: Lift?) {
    let animation = MinimapUpdate.animated.animation(response: snapshot.animationResponse)
    withAnimation(animation) { arrangement = next }
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
    lingerGeneration += 1
    let generation = lingerGeneration
    schedule(OverlayTiming.minimapLinger) { [weak self] in
      self?.lingerElapsed(generation)
    }
  }

  private func lingerElapsed(_ generation: Int) {
    guard generation == lingerGeneration, !isPointerInside, isIdle, isShown else { return }
    isShown = false
    onVisibilityChange(false)
  }
}
