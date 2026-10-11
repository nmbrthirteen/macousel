import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
  case general, layout, motion, appRules, displays, shortcuts, pointer, macSetup, about

  static let storageKey = "selectedSettingsSection"

  var id: String { rawValue }

  var title: String {
    switch self {
    case .general: "General"
    case .layout: "Layout"
    case .motion: "Motion"
    case .appRules: "App rules"
    case .displays: "Displays"
    case .shortcuts: "Shortcuts"
    case .pointer: "Pointer and gestures"
    case .macSetup: "Mac setup"
    case .about: "About"
    }
  }

  var systemImage: String {
    switch self {
    case .general: "gearshape"
    case .layout: "rectangle.split.3x1"
    case .motion: "speedometer"
    case .appRules: "app.dashed"
    case .displays: "display"
    case .shortcuts: "command"
    case .pointer: "cursorarrow.motionlines"
    case .macSetup: "checklist"
    case .about: "info.circle"
    }
  }

  var tint: Color {
    switch self {
    case .general: .gray
    case .layout: .blue
    case .motion: .purple
    case .appRules: .orange
    case .displays: .cyan
    case .shortcuts: .pink
    case .pointer: .green
    case .macSetup: .indigo
    case .about: .brown
    }
  }

  var group: SettingsSectionGroup {
    switch self {
    case .general: .general
    case .layout, .motion, .appRules, .displays: .windows
    case .shortcuts, .pointer: .input
    case .macSetup, .about: .system
    }
  }

  var keywords: [String] {
    switch self {
    case .general: ["permissions", "accessibility", "login", "startup", "launch", "restore", "session", "update", "automatic"]
    case .layout: ["gap", "width", "preset", "center", "default", "column", "spacing"]
    case .motion: ["animation", "speed", "focus", "border", "dim", "minimap", "overview", "reduce motion"]
    case .appRules: ["app", "float", "rule", "slot", "width", "exception"]
    case .displays: ["monitor", "screen", "display", "tile", "disable"]
    case .shortcuts: ["keyboard", "hotkey", "keys", "binding", "record"]
    case .pointer: ["mouse", "trackpad", "scroll", "swipe", "gesture", "finger", "focus follows mouse"]
    case .macSetup: ["spaces", "stage manager", "edge tiling", "mission control", "check", "accessibility"]
    case .about: ["version", "welcome", "guide", "icon", "update", "release", "install"]
    }
  }

  static func matching(_ query: String) -> [SettingsSection] {
    let needle = query.trimmingCharacters(in: .whitespaces)
    guard !needle.isEmpty else { return allCases }
    return allCases.filter { section in
      ([section.title] + section.keywords).contains { $0.localizedCaseInsensitiveContains(needle) }
    }
  }
}
