import WindowSystem

final class SystemShortcutRegistry: ShortcutRegistry {
  private let center = HotkeyCenter()

  func setBindings(_ bindings: [Hotkey: () -> Void]) {
    center.setBindings(bindings)
  }

  func removeAll() {
    center.removeAll()
  }
}
