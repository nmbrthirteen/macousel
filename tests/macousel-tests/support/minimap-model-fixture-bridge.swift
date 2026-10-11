@testable import Macousel

@MainActor
final class MinimapModelFixtureBridge {
  let model: MinimapModel

  init(_ fixture: ControllerFixture) {
    let clock = fixture.clock
    let model = MinimapModel { clock.schedule(after: $0, $1) }
    let host = fixture.overlays
    model.onSelect = { host.clickMinimap($0) }
    model.onMove = { host.dropFromMinimap($0, as: $1) }
    host.onMinimapShown = { [weak model] snapshot, update in
      model?.show(snapshot, update: update)
    }
    self.model = model
    if let snapshot = host.minimap { model.show(snapshot, update: .immediate) }
  }
}
