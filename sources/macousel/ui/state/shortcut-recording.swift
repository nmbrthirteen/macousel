import Observation
import AppKit
import Carbon.HIToolbox
import WindowSystem

@Observable
final class ShortcutRecording {
  private(set) var isRecording = false
  private(set) var message: String?

  @ObservationIgnored private let action: Action
  @ObservationIgnored private let store: PreferencesStore
  @ObservationIgnored private let monitor = KeyDownMonitor()

  init(action: Action, store: PreferencesStore) {
    self.action = action
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
    monitor.stop()
    isRecording = false
    store.isRecordingShortcut = false
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
    if let owner = owner(of: hotkey) {
      message = conflictMessage(for: hotkey, owner: owner)
      return
    }
    store.preferences.shortcuts[action, default: []].append(hotkey)
    message = nil
    stop()
  }

  private func owner(of hotkey: Hotkey) -> Action? {
    store.preferences.shortcuts.first { $0.value.contains(hotkey) }?.key
  }

  private func conflictMessage(for hotkey: Hotkey, owner: Action) -> String {
    owner == action
      ? "\(hotkey.displayString) is already added here."
      : "\(hotkey.displayString) is used by \(owner.title). Remove it there first."
  }
}
