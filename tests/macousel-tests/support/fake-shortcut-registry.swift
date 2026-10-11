import WindowSystem

@testable import Macousel

@MainActor
final class FakeShortcutRegistry: ShortcutRegistry {
  var failureCount = 0
  private var bindings: [Hotkey: () -> Void] = [:]

  var boundHotkeys: Set<Hotkey> { Set(bindings.keys) }

  func setBindings(_ bindings: [Hotkey: () -> Void]) -> Int {
    self.bindings = bindings
    return failureCount
  }

  func removeAll() {
    bindings = [:]
  }

  func trigger(_ hotkey: Hotkey) {
    bindings[hotkey]?()
  }
}
