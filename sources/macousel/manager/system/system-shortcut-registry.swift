import WindowSystem

final class SystemShortcutRegistry: ShortcutRegistry {
  private let center = HotkeyCenter()

  func setBindings(_ bindings: [Hotkey: () -> Void]) -> Int {
    center.setBindings(bindings)
  }

  func removeAll() {
    center.removeAll()
  }
}
