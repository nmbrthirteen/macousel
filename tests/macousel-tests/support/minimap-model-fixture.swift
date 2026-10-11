import StripCore

@testable import Macousel

@MainActor
final class MinimapModelFixture {
  let clock = ManualClock()
  let model: MinimapModel
  private(set) var selected: [WindowID] = []
  private(set) var moves: [(window: WindowID, target: DropTarget)] = []
  private(set) var visibility: [Bool] = []

  init(snapshot: MinimapSnapshot) {
    let clock = clock
    model = MinimapModel { clock.schedule(after: $0, $1) }
    model.onSelect = { [unowned self] in selected.append($0) }
    model.onMove = { [unowned self] in moves.append(($0, $1)) }
    model.onVisibilityChange = { [unowned self] in visibility.append($0) }
    model.show(snapshot, update: .immediate)
  }
}
