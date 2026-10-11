import Foundation
import StripCore
import WindowSystem

struct Preferences: Codable, Equatable {
  var layout = LayoutConfig()
  var shortcuts: [Action: [Hotkey]] = Action.defaultShortcuts
  var animationSpeed = AnimationSpeed.fast
  var showsFocusBorder = true
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
  var reversesSwipeDirection = false
  var displayFollowsPointer = true
  var focusFollowsMouse = false
  var mouseFollowsFocus = false
  var appRules: [AppRule] = AppRule.defaults
  var appShortcuts: [AppShortcut] = []
  var disabledDisplays: Set<String> = []
  var hasCompletedOnboarding = false
  var checksForUpdates = true

  static let swipeSensitivityRange = 0.5...2.0

  init() {}

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    func value<T: Decodable>(_ key: CodingKeys, or fallback: T) -> T {
      (try? values.decodeIfPresent(T.self, forKey: key)) ?? fallback
    }
    let defaults = Preferences()
    layout = value(.layout, or: defaults.layout)
    let savedShortcuts: [Action: [Hotkey]] = value(.shortcuts, or: [:])
    shortcuts = defaults.shortcuts.merging(savedShortcuts) { _, saved in saved }
    animationSpeed = value(.animationSpeed, or: defaults.animationSpeed)
    showsFocusBorder = value(.showsFocusBorder, or: defaults.showsFocusBorder)
    focusBorderWidth = value(.focusBorderWidth, or: defaults.focusBorderWidth)
    dimsInactiveWindows = value(.dimsInactiveWindows, or: defaults.dimsInactiveWindows)
    dimAmount = value(.dimAmount, or: defaults.dimAmount)
    showsMinimap = value(.showsMinimap, or: defaults.showsMinimap)
    menuBarIndicator = value(.menuBarIndicator, or: defaults.menuBarIndicator)
    restoresSession = value(.restoresSession, or: defaults.restoresSession)
    scrollGestureEnabled = value(.scrollGestureEnabled, or: defaults.scrollGestureEnabled)
    swipeGestureEnabled = value(.swipeGestureEnabled, or: defaults.swipeGestureEnabled)
    swipeFingers = value(.swipeFingers, or: defaults.swipeFingers)
    swipeSensitivity = value(.swipeSensitivity, or: defaults.swipeSensitivity)
    reversesSwipeDirection = value(.reversesSwipeDirection, or: defaults.reversesSwipeDirection)
    displayFollowsPointer = value(.displayFollowsPointer, or: defaults.displayFollowsPointer)
    focusFollowsMouse = value(.focusFollowsMouse, or: defaults.focusFollowsMouse)
    mouseFollowsFocus = value(.mouseFollowsFocus, or: defaults.mouseFollowsFocus)
    appRules = value(.appRules, or: defaults.appRules)
    appShortcuts = value(.appShortcuts, or: defaults.appShortcuts)
    disabledDisplays = value(.disabledDisplays, or: defaults.disabledDisplays)
    hasCompletedOnboarding = value(.hasCompletedOnboarding, or: defaults.hasCompletedOnboarding)
    checksForUpdates = value(.checksForUpdates, or: defaults.checksForUpdates)
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
    preferences.shortcuts = Action.defaultShortcuts
  }

  private static func stored(in defaults: UserDefaults) -> Preferences? {
    defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(Preferences.self, from: $0) }
  }

  private func save() {
    guard let data = try? JSONEncoder().encode(preferences) else { return }
    defaults.set(data, forKey: Self.key)
  }
}
