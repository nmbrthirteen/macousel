import Foundation
import StripCore
import WindowSystem

struct AppRule: Codable, Equatable, Identifiable {
  enum Behavior: Codable, Equatable {
    case float
    case width(Double)
    case slot(Int)
  }

  var bundleIdentifier: String
  var behavior: Behavior

  var id: String { bundleIdentifier }
}

struct Preferences: Codable, Equatable {
  var layout = LayoutConfig()
  var shortcuts: [Action: [Hotkey]] = Action.defaultShortcuts
  var animationSpeed = AnimationSpeed.fast
  var showsFocusBorder = false
  var focusBorderWidth: Double = 3
  var dimsInactiveWindows = false
  var dimAmount: Double = 0.25
  var showsMinimap = true
  var restoresSession = true
  var scrollGestureEnabled = true
  var swipeGestureEnabled = true
  var swipeFingers = 3
  var focusFollowsMouse = false
  var mouseFollowsFocus = false
  var appRules: [AppRule] = []
  var disabledDisplays: Set<String> = []
  var hasCompletedOnboarding = false

  init() {}

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    func value<T: Decodable>(_ key: CodingKeys, or fallback: T) -> T {
      (try? values.decodeIfPresent(T.self, forKey: key)) ?? fallback
    }
    let defaults = Preferences()
    layout = value(.layout, or: defaults.layout)
    shortcuts = value(.shortcuts, or: defaults.shortcuts)
    animationSpeed = value(.animationSpeed, or: defaults.animationSpeed)
    showsFocusBorder = value(.showsFocusBorder, or: defaults.showsFocusBorder)
    focusBorderWidth = value(.focusBorderWidth, or: defaults.focusBorderWidth)
    dimsInactiveWindows = value(.dimsInactiveWindows, or: defaults.dimsInactiveWindows)
    dimAmount = value(.dimAmount, or: defaults.dimAmount)
    showsMinimap = value(.showsMinimap, or: defaults.showsMinimap)
    restoresSession = value(.restoresSession, or: defaults.restoresSession)
    scrollGestureEnabled = value(.scrollGestureEnabled, or: defaults.scrollGestureEnabled)
    swipeGestureEnabled = value(.swipeGestureEnabled, or: defaults.swipeGestureEnabled)
    swipeFingers = value(.swipeFingers, or: defaults.swipeFingers)
    focusFollowsMouse = value(.focusFollowsMouse, or: defaults.focusFollowsMouse)
    mouseFollowsFocus = value(.mouseFollowsFocus, or: defaults.mouseFollowsFocus)
    appRules = value(.appRules, or: defaults.appRules)
    disabledDisplays = value(.disabledDisplays, or: defaults.disabledDisplays)
    hasCompletedOnboarding = value(.hasCompletedOnboarding, or: defaults.hasCompletedOnboarding)
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
    if let data = defaults.data(forKey: Self.key),
      let stored = try? JSONDecoder().decode(Preferences.self, from: data)
    {
      preferences = stored
    } else {
      preferences = Preferences()
    }
  }

  func resetShortcuts() {
    preferences.shortcuts = Action.defaultShortcuts
  }

  private func save() {
    guard let data = try? JSONEncoder().encode(preferences) else { return }
    defaults.set(data, forKey: Self.key)
  }
}
