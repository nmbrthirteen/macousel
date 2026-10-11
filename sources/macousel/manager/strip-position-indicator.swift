import Observation


@Observable
final class StripPositionIndicator {
  private(set) var position: StripPosition?

  @ObservationIgnored var isTiling = false {
    didSet { refresh() }
  }
  @ObservationIgnored private let state: TilingState

  init(state: TilingState) {
    self.state = state
  }

  func refresh() {
    let next = isTiling ? state.activePosition : nil
    if next != position { position = next }
  }
}
