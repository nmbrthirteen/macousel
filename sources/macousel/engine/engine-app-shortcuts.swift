final class EngineAppShortcuts {
  private let commands: any EngineCommanding
  private let activate: (String) -> Void

  init(commands: any EngineCommanding, activate: @escaping (String) -> Void) {
    self.commands = commands
    self.activate = activate
  }

  func jump(to bundleIdentifier: String) {
    Task {
      let snapshot = await commands.fetchSnapshot()
      switch EngineAppCycler.choice(bundleIdentifier: bundleIdentifier, in: snapshot) {
      case .focusColumn(let column): await commands.send(["window", "focus", "\(column)"])
      case .activateApp: activate(bundleIdentifier)
      }
    }
  }
}
