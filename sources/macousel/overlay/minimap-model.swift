import SwiftUI

@Observable
final class MinimapModel {
  var snapshot = MinimapSnapshot.empty
  var isShown = false
  private(set) var updateAnimation: Animation?

  @ObservationIgnored let icons = MinimapIconCache()

  func apply(_ snapshot: MinimapSnapshot, update: MinimapUpdate) {
    updateAnimation = update.animation(response: snapshot.animationResponse)
    self.snapshot = snapshot
  }
}
