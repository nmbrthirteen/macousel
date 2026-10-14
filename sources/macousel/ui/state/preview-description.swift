import StripCore
import WindowSystem

enum PreviewDescription {
  static func layout(_ config: LayoutConfig) -> String {
    "Preview: \(points(config.innerGap)) between windows, \(points(config.outerGap)) at screen edges, "
      + "new windows \(width(config.defaultWidth)), focused column centered \(centering(config.centerMode))"
  }

  static func motion(_ preferences: Preferences) -> String {
    var parts = ["\(preferences.animationSpeed.title.lowercased()) animation"]
    if preferences.showsFocusBorder {
      parts.append("focus border \(points(preferences.focusBorderWidth)) wide")
    }
    if preferences.dimsInactiveWindows {
      parts.append("other windows dimmed \(preferences.dimAmount.wholePercent)%")
    }
    return "Preview: " + parts.joined(separator: ", ")
  }


  static func swipe(fingers: Int, reversed: Bool, sensitivity: Double) -> String {
    let direction = reversed ? "right" : "left"
    let strength = sensitivity.formatted(.number.precision(.fractionLength(1)))
    return "Preview: a swipe left with \(fingers) fingers moves the strip \(direction), sensitivity \(strength)"
  }

  static func floating(keepsOnTop: Bool) -> String {
    keepsOnTop
      ? "Preview: a floating window stays above the tiled windows"
      : "Preview: a floating window can fall behind the focused window"
  }

  static func displays(_ displays: [Display], disabled: Set<String>) -> String {
    let entries = displays.map { "\($0.name) \(disabled.contains($0.uuid) ? "not tiled" : "tiled")" }
    let noun = displays.count == 1 ? "display" : "displays"
    return "Preview: \(displays.count) \(noun), " + entries.joined(separator: ", ")
  }

  private static func points(_ value: Double) -> String {
    let count = Int(value)
    return "\(count) \(count == 1 ? "point" : "points")"
  }

  private static func width(_ fraction: Double) -> String {
    abs(fraction - 0.5) < 0.005 ? "half the screen wide" : "\(fraction.wholePercent)% of the screen wide"
  }

  private static func centering(_ mode: CenterMode) -> String {
    switch mode {
    case .never: "never"
    case .onOverflow: "when it does not all fit"
    case .always: "always"
    }
  }
}
