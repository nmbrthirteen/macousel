import StripCore

final class DragRearrangement {
  private let state: TilingState
  private let presenter: LayoutPresenter
  private(set) var startingStrips: [Workspace.Key: Strip] = [:]
  private var shown: [Workspace.Key: Strip]?

  init(state: TilingState, presenter: LayoutPresenter) {
    self.state = state
    self.presenter = presenter
  }

  func begin() {
    startingStrips = state.activeKeys.reduce(into: [:]) { strips, key in
      strips[key] = state.workspaces[key]?.strip
    }
    shown = nil
  }

  func show(_ plan: DropPlan?) {
    let target = plan?.changesLayout == true ? plan?.strips : nil
    guard target != shown else { return }
    shown = target
    restoreStrips()
    for (key, strip) in target ?? [:] { state.workspaces[key]?.strip = strip }
    presenter.relayout()
  }

  func restore() {
    shown = nil
    restoreStrips()
  }

  private func restoreStrips() {
    for (key, strip) in startingStrips { state.workspaces[key]?.strip = strip }
  }
}
