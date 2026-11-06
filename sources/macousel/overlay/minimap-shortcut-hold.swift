import AppKit

/// Watches the shortcut base modifiers only while the minimap is on screen.
final class MinimapShortcutHold {
  var onRelease: () -> Void = {}

  private let base: () -> ShortcutBase
  private var required: NSEvent.ModifierFlags = []
  private var wasHeld = false
  private var monitors: [Any] = []

  init(base: @escaping () -> ShortcutBase) {
    self.base = base
  }

  var isHeld: Bool {
    !required.isEmpty && Self.holds(NSEvent.modifierFlags, required)
  }

  func start() {
    guard monitors.isEmpty else { return }
    required = Self.flags(of: base())
    wasHeld = isHeld
    let global = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
      let flags = event.modifierFlags
      MainActor.assumeIsolated { self?.changed(to: flags) }
    }
    let local = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
      self?.changed(to: event.modifierFlags)
      return event
    }
    monitors = [global, local].compactMap { $0 }
  }

  func stop() {
    monitors.forEach(NSEvent.removeMonitor)
    monitors = []
  }

  private func changed(to flags: NSEvent.ModifierFlags) {
    let held = Self.holds(flags, required)
    defer { wasHeld = held }
    if wasHeld, !held { onRelease() }
  }

  private static func holds(_ flags: NSEvent.ModifierFlags, _ required: NSEvent.ModifierFlags)
    -> Bool
  {
    flags.intersection(.deviceIndependentFlagsMask).isSuperset(of: required)
  }

  private static func flags(of base: ShortcutBase) -> NSEvent.ModifierFlags {
    switch base {
    case .controlOption: [.control, .option]
    case .option: [.option]
    case .commandOption: [.command, .option]
    }
  }
}
