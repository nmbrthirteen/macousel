import AppKit
import Carbon.HIToolbox
import Observation
import WindowSystem

@Observable
final class ShortcutRecording {
  private(set) var isRecording = false
  private(set) var message: String?

  @ObservationIgnored var onStop: (() -> Void)?
  @ObservationIgnored private let target: ShortcutOwner
  @ObservationIgnored private let store: PreferencesStore
  @ObservationIgnored private let monitor = KeyDownMonitor()

  init(target: ShortcutOwner, store: PreferencesStore) {
    self.target = target
    self.store = store
  }

  func toggle() {
    isRecording ? stop() : start()
  }

  func start() {
    message = nil
    isRecording = true
    store.isRecordingShortcut = true
    monitor.start { [weak self] event in
      self?.handle(event)
      return nil
    }
  }

  func stop() {
    let wasRecording = isRecording
    monitor.stop()
    isRecording = false
    store.isRecordingShortcut = false
    if wasRecording { onStop?() }
  }

  func record(_ hotkey: Hotkey) {
    if let owner = store.preferences.owner(of: hotkey) {
      message = conflictMessage(for: hotkey, owner: owner)
      return
    }
    store.preferences.assign(hotkey, to: target)
    message = nil
    stop()
  }

  private func handle(_ event: NSEvent) {
    let plain = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    if event.keyCode == UInt16(kVK_Escape), plain.isDisjoint(with: [.control, .option, .command]) {
      stop()
      return
    }
    guard let hotkey = Hotkey(event: event) else {
      message = "Include ⌃, ⌥, or ⌘ in the shortcut."
      return
    }
    record(hotkey)
  }

  private func conflictMessage(for hotkey: Hotkey, owner: ShortcutOwner) -> String {
    owner == target
      ? "\(hotkey.displayString) is already added here."
      : "\(hotkey.displayString) is used by \(name(of: owner)). Remove it there first."
  }

  private func name(of owner: ShortcutOwner) -> String {
    switch owner {
    case .action(let action): action.title
    case .app(let bundleIdentifier): AppIdentity(bundleIdentifier: bundleIdentifier).name
    }
  }
}
