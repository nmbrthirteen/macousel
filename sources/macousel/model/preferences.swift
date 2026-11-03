import Foundation
import StripCore
import WindowSystem
import os

struct Preferences: Codable, Equatable {
  var engine = WindowEngine.preferred
  var layout = LayoutConfig()
  var shortcutBase = ShortcutBase.controlOption
  var shortcuts: [Action: [Hotkey]] = Action.defaultShortcuts
  var animationSpeed = AnimationSpeed.fast
  var showsFocusBorder = false
  var focusBorderWidth: Double = 3
  var dimsInactiveWindows = false
  var dimAmount: Double = 0.25
  var showsMinimap = true
  var menuBarIndicator = MenuBarIndicator.position
  var restoresSession = true
  var scrollGestureEnabled = true
  var swipeGestureEnabled = true
  var swipeFingers = 4
  var swipeSensitivity = 1.0
  var swipeStep = SwipeStep.column
  var reversesSwipeDirection = false
  var displayFollowsPointer = true
  var focusFollowsMouse = false
  var mouseFollowsFocus = false
  var keepsFloatingWindowsOnTop = true
  var appRules: [AppRule] = AppRule.defaults
  var appShortcuts: [AppShortcut] = []
  var disabledDisplays: Set<String> = []
  var hasCompletedOnboarding = false
  var checksForUpdates = true

  static let swipeSensitivityRange = 0.5...2.0
  static let focusBorderWidthRange = 1.0...8.0
  static let swipeFingerOptions = [3, 4]
  static let slotRange = Action.places

  // Stored preferences fall back per key so one bad value never resets the rest. An imported
  // file sets this key, so a typo there fails loudly instead.
  static let strictDecoding = CodingUserInfoKey(rawValue: "dev.macousel.strictDecoding")!

  init() {}

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let strict = decoder.userInfo[Self.strictDecoding] as? Bool == true
    func value<T: Decodable>(_ key: CodingKeys, or fallback: T) throws -> T {
      if strict { return try values.decodeIfPresent(T.self, forKey: key) ?? fallback }
      return (try? values.decodeIfPresent(T.self, forKey: key)) ?? fallback
    }
    let defaults = Preferences()
    engine = try value(.engine, or: defaults.engine)
    layout = try value(.layout, or: defaults.layout)
    let savedShortcuts: [Action: [Hotkey]] = try value(.shortcuts, or: [:])
    shortcutBase = try value(.shortcutBase, or: defaults.shortcutBase)
    shortcuts = Action.defaultShortcuts(base: shortcutBase)
      .merging(savedShortcuts) { _, saved in saved }
    animationSpeed = try value(.animationSpeed, or: defaults.animationSpeed)
    showsFocusBorder = try value(.showsFocusBorder, or: defaults.showsFocusBorder)
    focusBorderWidth = try value(.focusBorderWidth, or: defaults.focusBorderWidth)
    dimsInactiveWindows = try value(.dimsInactiveWindows, or: defaults.dimsInactiveWindows)
    dimAmount = try value(.dimAmount, or: defaults.dimAmount)
    showsMinimap = try value(.showsMinimap, or: defaults.showsMinimap)
    menuBarIndicator = try value(.menuBarIndicator, or: defaults.menuBarIndicator)
    restoresSession = try value(.restoresSession, or: defaults.restoresSession)
    scrollGestureEnabled = try value(.scrollGestureEnabled, or: defaults.scrollGestureEnabled)
    swipeGestureEnabled = try value(.swipeGestureEnabled, or: defaults.swipeGestureEnabled)
    swipeFingers = try value(.swipeFingers, or: defaults.swipeFingers)
    swipeSensitivity = try value(.swipeSensitivity, or: defaults.swipeSensitivity)
    swipeStep = try value(.swipeStep, or: defaults.swipeStep)
    reversesSwipeDirection = try value(.reversesSwipeDirection, or: defaults.reversesSwipeDirection)
    displayFollowsPointer = try value(.displayFollowsPointer, or: defaults.displayFollowsPointer)
    focusFollowsMouse = try value(.focusFollowsMouse, or: defaults.focusFollowsMouse)
    mouseFollowsFocus = try value(.mouseFollowsFocus, or: defaults.mouseFollowsFocus)
    keepsFloatingWindowsOnTop = try value(
      .keepsFloatingWindowsOnTop, or: defaults.keepsFloatingWindowsOnTop)
    appRules = try value(.appRules, or: defaults.appRules)
    appShortcuts = try value(.appShortcuts, or: defaults.appShortcuts)
    disabledDisplays = try value(.disabledDisplays, or: defaults.disabledDisplays)
    hasCompletedOnboarding = try value(.hasCompletedOnboarding, or: defaults.hasCompletedOnboarding)
    checksForUpdates = try value(.checksForUpdates, or: defaults.checksForUpdates)
  }

  var clampedSwipeSensitivity: Double {
    min(
      max(swipeSensitivity, Self.swipeSensitivityRange.lowerBound),
      Self.swipeSensitivityRange.upperBound)
  }

  var outOfRangeValue: String? {
    if !Self.focusBorderWidthRange.contains(focusBorderWidth) { return "focusBorderWidth" }
    if !Self.swipeFingerOptions.contains(swipeFingers) { return "swipeFingers" }
    if layout.presetWidths.isEmpty
      || !layout.presetWidths.allSatisfy(Strip.widthFractionRange.contains)
    {
      return "layout.presetWidths"
    }
    for rule in appRules {
      switch rule.behavior {
      case .width(let fraction) where !Strip.widthFractionRange.contains(fraction):
        return "appRules width for \(rule.bundleIdentifier)"
      case .slot(let place) where !Self.slotRange.contains(place):
        return "appRules slot for \(rule.bundleIdentifier)"
      default: continue
      }
    }
    return nil
  }

  func rule(for bundleIdentifier: String?) -> AppRule.Behavior? {
    appRules.first { $0.bundleIdentifier == bundleIdentifier }?.behavior
  }
}

@Observable
final class PreferencesStore {
  private static let key = "preferences"

  var preferences: Preferences {
    didSet {
      guard preferences != oldValue else { return }
      save()
      onChange?()
    }
  }

  var isRecordingShortcut = false {
    didSet {
      if isRecordingShortcut != oldValue { onChange?() }
    }
  }

  @ObservationIgnored var onChange: (() -> Void)?
  @ObservationIgnored private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    preferences = Self.stored(in: defaults) ?? Preferences()
  }

  func reload() {
    guard let stored = Self.stored(in: defaults) else { return }
    preferences = stored
  }

  func resetShortcuts() {
    preferences.shortcuts = Action.defaultShortcuts(base: preferences.shortcutBase)
  }

  func setShortcutBase(_ base: ShortcutBase) {
    var updated = preferences
    let old = Action.defaultShortcuts(base: updated.shortcutBase)
    let new = Action.defaultShortcuts(base: base)
    for (action, hotkeys) in updated.shortcuts where hotkeys == old[action] {
      updated.shortcuts[action] = new[action]
    }
    updated.shortcutBase = base
    preferences = updated
  }

  private static let logger = Logger(subsystem: Log.subsystem, category: "preferences")
  static let backupKey = "preferences.unreadable"

  // A file that no longer decodes is kept under another key, so the next save cannot
  // overwrite the user's settings with defaults.
  private static func stored(in defaults: UserDefaults) -> Preferences? {
    guard let data = defaults.data(forKey: key) else { return nil }
    do {
      return try JSONDecoder().decode(Preferences.self, from: data)
    } catch {
      logger.error("Stored preferences do not decode, kept a backup: \(error, privacy: .public)")
      defaults.set(data, forKey: backupKey)
      return nil
    }
  }

  private func save() {
    guard let data = try? JSONEncoder().encode(preferences) else { return }
    defaults.set(data, forKey: Self.key)
  }
}

extension Preferences {
  var hasWidthRule: Bool {
    appRules.contains { rule in
      if case .width = rule.behavior { true } else { false }
    }
  }
}
