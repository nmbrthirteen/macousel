import CoreGraphics
import StripCore
import WindowSystem

@MainActor
struct ExpectedStrip {
  var strip = Strip()
  var displays: [Display]
  var display: Display
  var config = LayoutConfig()

  init(on display: Display = .fake(), among displays: [Display]? = nil) {
    self.display = display
    self.displays = displays ?? [display]
  }

  init(
    columns: [CGWindowID], fraction: Double = 0.5, on display: Display = .fake(),
    among displays: [Display]? = nil
  ) {
    self.init(on: display, among: displays)
    columns.forEach { append($0, .fraction(fraction)) }
  }

  mutating func append(_ window: CGWindowID, _ width: ColumnWidth = .fraction(0.5)) {
    strip.append(WindowID(window), width: width)
  }

  mutating func focus(_ window: CGWindowID) {
    strip.focus(WindowID(window))
    strip.scrollToFocus(viewportWidth: display.visibleFrame.width, config: config)
  }

  mutating func apply(_ change: (inout Strip) -> Void) {
    change(&strip)
    strip.scrollToFocus(viewportWidth: display.visibleFrame.width, config: config)
  }

  var layout: StripLayout {
    strip.layout(in: display.visibleFrame, config: config)
  }

  var frames: [CGWindowID: CGRect] {
    let policy = ParkingPolicy(
      displayBounds: display.frame,
      hasLeftNeighbor: display.hasNeighbor(.left, among: displays),
      hasRightNeighbor: display.hasNeighbor(.right, among: displays))
    return layout.placements.reduce(into: [:]) { frames, placement in
      frames[placement.window.rawValue] = policy.frame(for: placement, in: display.visibleFrame)
    }
  }

  func frame(of window: CGWindowID) -> CGRect? {
    frames[window]
  }
}
