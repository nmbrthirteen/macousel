import AppKit
import Observation
import WindowSystem
import os

final class MenuBarController: NSObject, NSMenuDelegate {
  private static let logger = Logger(subsystem: Log.subsystem, category: "menu")

  private let manager: WindowManager
  private let updater: Updater
  private let store: PreferencesStore
  private let diagnostics: DiagnosticsAction
  private let showSettings: (SettingsSection?) -> Void
  private let showWelcome: () -> Void
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private var shownPresentation: MenuBarPresentation?

  init(
    manager: WindowManager, updater: Updater, store: PreferencesStore,
    diagnostics: DiagnosticsAction, showSettings: @escaping (SettingsSection?) -> Void,
    showWelcome: @escaping () -> Void
  ) {
    self.manager = manager
    self.updater = updater
    self.store = store
    self.diagnostics = diagnostics
    self.showSettings = showSettings
    self.showWelcome = showWelcome
    super.init()
    let menu = NSMenu()
    menu.autoenablesItems = false
    menu.delegate = self
    statusItem.menu = menu
    statusItem.button?.imagePosition = .imageLeading
    statusItem.button?.font = .monospacedDigitSystemFont(
      ofSize: NSFont.systemFontSize, weight: .regular)
    refreshButton()
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    menu.removeAllItems()
    menu.addItem(disabledItem(statusText))
    if let notice = manager.notice { menu.addItem(disabledItem(notice)) }
    if manager.status == .needsPermission {
      menu.addItem(
        actionItem("Grant Accessibility Access…") { AccessibilityGuide.shared.begin() })
    }
    if case .available(let release) = updater.state {
      menu.addItem(
        actionItem("Update to \(release.version.description)…") { [showSettings] in
          showSettings(.about)
        })
    }
    menu.addItem(.separator())
    menu.addItem(
      actionItem(manager.status == .paused ? "Resume Tiling" : "Pause Tiling") { [manager] in
        manager.perform(.togglePaused)
      })
    menu.addItem(shortcutsItem())
    menu.addItem(.separator())
    menu.addItem(
      actionItem("Settings…", keyEquivalent: ",") { [showSettings] in showSettings(nil) })
    menu.addItem(actionItem("Show Welcome Guide", handler: showWelcome))
    let save = actionItem("Save Diagnostics") { [diagnostics] in
      Task(priority: .utility) { await diagnostics.save() }
    }
    save.isEnabled = !diagnostics.isSaving
    menu.addItem(save)
    if let message = diagnostics.failureMessage { menu.addItem(disabledItem(message)) }
    menu.addItem(actionItem("Restart Macousel") { [weak self] in self?.restart() })
    menu.addItem(.separator())
    menu.addItem(actionItem("Quit Macousel", keyEquivalent: "q") { NSApp.terminate(nil) })
  }

  private func actionItem(
    _ title: String, keyEquivalent: String = "", handler: @escaping () -> Void
  ) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: #selector(run(_:)), keyEquivalent: keyEquivalent)
    item.target = self
    item.representedObject = handler
    return item
  }

  @objc private func run(_ item: NSMenuItem) {
    (item.representedObject as? () -> Void)?()
  }

  private func disabledItem(_ title: String) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
    item.isEnabled = false
    return item
  }

  private func shortcutsItem() -> NSMenuItem {
    let submenu = NSMenu(title: "Shortcuts")
    submenu.autoenablesItems = false
    for section in ShortcutMenuItems.sections(in: store.preferences) {
      let title = MenuTitle.titleCased(section.title)
      let sectionMenu = NSMenu(title: title)
      sectionMenu.autoenablesItems = false
      for shortcut in section.items {
        let item = actionItem(MenuTitle.titleCased(shortcut.title)) { [manager] in manager.perform(shortcut.action) }
        if #available(macOS 14.4, *) {
          item.subtitle = shortcut.keys
        } else {
          item.title = "\(item.title)  \(shortcut.keys)"
        }
        sectionMenu.addItem(item)
      }
      let sectionItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
      sectionItem.submenu = sectionMenu
      submenu.addItem(sectionItem)
    }
    submenu.addItem(.separator())
    submenu.addItem(
      actionItem("Edit Shortcuts…") { [showSettings] in showSettings(.shortcuts) })
    let item = NSMenuItem(title: "Shortcuts", action: nil, keyEquivalent: "")
    item.submenu = submenu
    return item
  }

  private func restart() {
    do {
      try AppRestarter().restart()
    } catch {
      Self.logger.error("Restart failed: \(error.localizedDescription, privacy: .public)")
    }
  }

  private var statusText: String {
    switch manager.status {
    case .running: "Running"
    case .paused: "Paused"
    case .needsPermission: "Needs Accessibility Access"
    }
  }

  // Each change re-arms the tracking, so the button follows status, position, and the
  // indicator preference without polling.
  private func refreshButton() {
    let presentation = withObservationTracking {
      MenuBarPresentation(
        status: manager.status, position: manager.position,
        indicator: store.preferences.menuBarIndicator)
    } onChange: { [weak self] in
      Task { @MainActor in self?.refreshButton() }
    }
    guard presentation != shownPresentation, let button = statusItem.button else { return }
    shownPresentation = presentation
    button.setAccessibilityLabel(presentation.accessibilityLabel)
    button.title = ""
    switch presentation.content {
    case .symbol(let name):
      button.image = Self.symbol(name)
    case .pills(let position):
      button.image = MenuBarPillGeometry(position: position).map(MenuBarPillImage.make)
    case .pages(let position):
      button.image = MenuBarPagesGeometry(position: position).map(MenuBarPagesImage.make)
    case .symbolWithCount(let symbol, let text):
      button.image = Self.symbol(symbol)
      button.title = text
    }
  }

  private static func symbol(_ name: String) -> NSImage? {
    NSImage(systemSymbolName: name, accessibilityDescription: nil)
  }
}
