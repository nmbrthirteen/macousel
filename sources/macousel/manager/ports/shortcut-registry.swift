import WindowSystem

protocol ShortcutRegistry: AnyObject {
  func setBindings(_ bindings: [Hotkey: () -> Void]) -> Int
  func removeAll()
}
