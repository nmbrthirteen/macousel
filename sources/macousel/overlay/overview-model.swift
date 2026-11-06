import AppKit
import StripCore
import SwiftUI

@Observable
final class OverviewModel {
  struct Lift: Equatable {
    var window: WindowID
    var rect: CGRect
  }

  private struct RealFrame {
    var layout: CGRect?
    var real: CGRect
  }

  struct ResizeLabel: Equatable {
    var window: WindowID
    var text: String
  }

  private(set) var snapshot = OverviewSnapshot.empty
  private(set) var arrangement = OverviewSnapshot.empty
  private(set) var lift: Lift?
  private(set) var resizeLabel: ResizeLabel?
  private(set) var activeDivider: WindowID?
  private(set) var isExpanded = false
  private(set) var hovered: WindowID?
  private(set) var displayFrame = CGRect.zero
  let previews: OverviewPreviews
  @ObservationIgnored var interaction = OverviewInteraction.idle
  @ObservationIgnored var onSelect: (WindowID) -> Void = { _ in }
  @ObservationIgnored var onDismiss: () -> Void = {}
  @ObservationIgnored var onMove: (WindowID, DropTarget) -> Void = { _, _ in }
  @ObservationIgnored var onColumnWidth: (WindowID, Double) -> Void = { _, _ in }
  @ObservationIgnored var onRowHeight: (WindowID, Double, VerticalNeighbor) -> Void = { _, _, _ in }
  @ObservationIgnored private var realFrames: [WindowID: RealFrame] = [:]
  @ObservationIgnored private let icons = AppIconCache(iconSide: Metrics.Overview.iconSide)

  init(previews: OverviewPreviews) {
    self.previews = previews
  }

  func icon(for bundleIdentifier: String?) -> NSImage? {
    bundleIdentifier.map(icons.icon(for:))
  }

  func show(_ snapshot: OverviewSnapshot) {
    let snapshot = placed(snapshot)
    guard snapshot != self.snapshot else { return }
    self.snapshot = snapshot
    guard case .idle = interaction else { return }
    animated { arrangement = snapshot }
  }

  func prepare(_ snapshot: OverviewSnapshot, on displayFrame: CGRect) {
    interaction = .idle
    realFrames = [:]
    unanimated {
      self.snapshot = snapshot
      arrangement = snapshot
      self.displayFrame = displayFrame
      isExpanded = false
      hovered = nil
      lift = nil
      resizeLabel = nil
      activeDivider = nil
    }
  }

  // The capture reports where each window really is, which can differ from the layout when an
  // app holds its window to a minimum size. The real frame holds until the layout moves it.
  func adopt(_ frames: [WindowID: CGRect]) {
    guard !frames.isEmpty else { return }
    let layout = Dictionary(
      snapshot.columns.flatMap(\.cards).map { ($0.window, $0.frame) },
      uniquingKeysWith: { first, _ in first })
    realFrames = frames.reduce(into: [:]) { placed, entry in
      placed[entry.key] = RealFrame(layout: layout[entry.key] ?? nil, real: entry.value)
    }
    let adopted = placed(snapshot)
    unanimated {
      snapshot = adopted
      arrangement = adopted
    }
  }

  private func placed(_ snapshot: OverviewSnapshot) -> OverviewSnapshot {
    guard !realFrames.isEmpty else { return snapshot }
    return snapshot.placing { card in
      realFrames[card.window].flatMap { $0.layout == card.frame ? $0.real : nil }
    }
  }

  func expand() {
    withAnimation(flight(response: OverlayTiming.overviewOpenResponse)) { isExpanded = true }
  }

  func collapse(completion: @escaping () -> Void) {
    withAnimation(
      flight(response: OverlayTiming.overviewCloseResponse), completionCriteria: .removed,
      { isExpanded = false }, completion: completion)
  }

  func hover(_ window: WindowID, isInside: Bool) {
    if isInside {
      hovered = window
    } else if hovered == window {
      hovered = nil
    }
  }

  func setArrangement(
    _ next: OverviewSnapshot, lift: Lift?, label: ResizeLabel? = nil, divider: WindowID? = nil
  ) {
    if next != arrangement { animated { arrangement = next } }
    unanimated {
      self.lift = lift
      resizeLabel = label
      activeDivider = divider
    }
  }

  func endInteraction() {
    interaction = .idle
    animated {
      arrangement = snapshot
      lift = nil
      resizeLabel = nil
      activeDivider = nil
    }
  }

  var animates: Bool {
    snapshot.springResponse != nil && !OverlayPanel.reducesMotion
  }

  private func flight(response: Double) -> Animation {
    animates
      ? .spring(response: response, dampingFraction: OverlayTiming.criticalDamping)
      : .easeOut(duration: OverlayTiming.fade)
  }

  private func animated(_ change: () -> Void) {
    guard animates else {
      unanimated(change)
      return
    }
    withAnimation(flight(response: OverlayTiming.overviewOpenResponse), change)
  }

  private func unanimated(_ change: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, change)
  }
}
