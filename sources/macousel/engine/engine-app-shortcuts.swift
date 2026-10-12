final class EngineAppShortcuts {
  private let commands: any EngineCommanding
  private let reorder: EngineReorder
  private let activate: (String) -> Void

  init(
    commands: any EngineCommanding, reorder: EngineReorder, activate: @escaping (String) -> Void
  ) {
    self.commands = commands
    self.reorder = reorder
    self.activate = activate
  }

  func jump(to bundleIdentifier: String) {
    Task {
      let snapshot = await commands.fetchSnapshot()
      switch EngineAppCycler.choice(bundleIdentifier: bundleIdentifier, in: snapshot) {
      case .focusWindow(let window): await reorder.focus(window)
      case .activateApp: activate(bundleIdentifier)
      }
    }
  }
}
