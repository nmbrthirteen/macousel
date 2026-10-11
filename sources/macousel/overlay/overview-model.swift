import AppKit
import StripCore
import SwiftUI

@Observable
final class OverviewModel {
  struct Lift: Equatable {
    var window: WindowID
    var rect: CGRect
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
  @ObservationIgnored var interaction = OverviewInteraction.idle
  @ObservationIgnored var onSelect: (WindowID) -> Void = { _ in }
  @ObservationIgnored var onDismiss: () -> Void = {}
  @ObservationIgnored var onMove: (WindowID, DropTarget) -> Void = { _, _ in }
  @ObservationIgnored var onColumnWidth: (WindowID, Double) -> Void = { _, _ in }
  @ObservationIgnored var onRowHeight: (WindowID, Double, VerticalNeighbor) -> Void = { _, _, _ in }
  @ObservationIgnored private let icons = OverviewIconCache()

  func icon(for bundleIdentifier: String?) -> NSImage? {
    icons.icon(for: bundleIdentifier)
  }

  func show(_ snapshot: OverviewSnapshot) {
    guard snapshot != self.snapshot else { return }
    self.snapshot = snapshot
    guard case .idle = interaction else { return }
    animated { arrangement = snapshot }
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

  private var animates: Bool {
    snapshot.springResponse != nil && !OverlayPanel.reducesMotion
  }

  private func animated(_ change: () -> Void) {
    guard let response = snapshot.springResponse, animates else {
      unanimated(change)
      return
    }
    withAnimation(.spring(response: response, dampingFraction: OverlayTiming.springDamping)) {
      change()
    }
  }

  private func unanimated(_ change: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, change)
  }
}
