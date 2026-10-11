import os

nonisolated final class InputEventTapModifiers: Sendable {
  private let storage = OSAllocatedUnfairLock(initialState: Hotkey.Modifiers.RawValue())

  var value: Hotkey.Modifiers {
    get { Hotkey.Modifiers(rawValue: storage.withLock { $0 }) }
    set { storage.withLock { $0 = newValue.rawValue } }
  }
}
