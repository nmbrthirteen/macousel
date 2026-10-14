import CoreGraphics

struct SceneScript {
  private static let keyHold = Duration.milliseconds(900)
  private static let releaseHold = Duration.milliseconds(500)

  private(set) var frames: [SceneFrame] = []
  var strip: SceneStrip

  init(strip: SceneStrip) {
    self.strip = strip
  }

  mutating func show(hold: Duration, cursor: SceneCursor? = nil, menu: SceneMenuState? = nil) {
    frames.append(
      SceneFrame(
        windows: strip.windows, position: strip.position, cursor: cursor, menu: menu, hold: hold))
  }

  mutating func press(_ keys: String?, change: (inout SceneStrip) -> Void) {
    change(&strip)
    frames.append(
      SceneFrame(windows: strip.windows, position: strip.position, keys: keys, hold: Self.keyHold))
    show(hold: Self.releaseHold)
  }

  mutating func append(_ frame: SceneFrame) {
    frames.append(frame)
  }
}
