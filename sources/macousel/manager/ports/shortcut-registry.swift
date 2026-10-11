import WindowSystem

protocol ShortcutRegistry: AnyObject {
  func setBindings(_ bindings: [Hotkey: () -> Void])
  func removeAll()
}
