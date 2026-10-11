import WindowSystem

@testable import Macousel

@MainActor
final class FakeShortcutRegistry: ShortcutRegistry {
  private var bindings: [Hotkey: () -> Void] = [:]

  var boundHotkeys: Set<Hotkey> { Set(bindings.keys) }

  func setBindings(_ bindings: [Hotkey: () -> Void]) {
    self.bindings = bindings
  }

  func removeAll() {
    bindings = [:]
  }

  func trigger(_ hotkey: Hotkey) {
    bindings[hotkey]?()
  }
}
