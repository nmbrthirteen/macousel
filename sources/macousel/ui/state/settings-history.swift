// Back and forward through the panes visited since Settings opened, like System Settings.
struct SettingsHistory {
  private(set) var current: SettingsSection
  private var back: [SettingsSection] = []
  private var forward: [SettingsSection] = []

  init(current: SettingsSection) {
    self.current = current
  }

  var canGoBack: Bool { !back.isEmpty }
  var canGoForward: Bool { !forward.isEmpty }

  mutating func visit(_ section: SettingsSection) {
    guard section != current else { return }
    back.append(current)
    forward.removeAll()
    current = section
  }

  mutating func goBack() {
    guard let previous = back.popLast() else { return }
    forward.append(current)
    current = previous
  }

  mutating func goForward() {
    guard let next = forward.popLast() else { return }
    back.append(current)
    current = next
  }
}
