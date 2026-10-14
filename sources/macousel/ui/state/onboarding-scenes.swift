import CoreGraphics

enum OnboardingScenes {
  private typealias Scene = OnboardingSceneMetrics

  private static let styles = SceneWindowStyle.allCases
  private static let widthShares = [0.5, 0.6, 0.45, 0.5, 0.55]
  private static let opening = Duration.milliseconds(1400)
  private static let closing = Duration.milliseconds(1600)
  private static let cursorTravel = Duration.milliseconds(900)
  private static let click = Duration.milliseconds(180)
  private static let settle = Duration.milliseconds(700)
  private static let cursorStart = CGPoint(x: 400, y: 236)
  private static let cursorRest = CGPoint(x: 330, y: 212)

  private static let looseFrames = [
    CGRect(x: 26, y: 46, width: 190, height: 150),
    CGRect(x: 168, y: 70, width: 210, height: 160),
    CGRect(x: 92, y: 98, width: 170, height: 132),
    CGRect(x: 268, y: 40, width: 170, height: 128),
    CGRect(x: 40, y: 128, width: 200, height: 110),
  ]

  static func welcome(keys: (Action) -> String?) -> [SceneFrame] {
    var script = SceneScript(strip: SceneStrip(styles: styles, widthShares: widthShares))
    script.show(hold: opening)
    for _ in styles.dropFirst() {
      script.press(keys(.focusRight)) { $0.focus($0.focused + 1) }
    }
    script.press(keys(.focusColumn(Action.places.lowerBound))) { $0.focus(0) }
    script.show(hold: closing)
    return script.frames
  }

  static func access(keys: (Action) -> String?) -> [SceneFrame] {
    var script = SceneScript(strip: SceneStrip(styles: styles, widthShares: widthShares))
    let scattered = zip(styles.indices, styles).map { index, style in
      SceneWindow(id: index, style: style, rect: looseFrames[index], isFocused: false)
    }
    let toggle = Scene.toggleCenter
    script.append(asking(scattered, cursor: cursorStart, isOn: false, hold: settle))
    script.append(asking(scattered, cursor: toggle, isOn: false, hold: cursorTravel))
    script.append(asking(scattered, cursor: toggle, isPressed: true, isOn: false, hold: click))
    script.append(asking(scattered, cursor: toggle, isOn: true, hold: settle))
    script.show(hold: opening, cursor: SceneCursor(point: cursorRest))
    script.press(keys(.focusRight)) { $0.focus(1) }
    script.show(hold: closing)
    return script.frames
  }

  static func menuBar() -> [SceneFrame] {
    var script = SceneScript(
      strip: SceneStrip(styles: styles, widthShares: widthShares, focused: 1))
    let item = CGPoint(x: Scene.appItem.midX, y: Scene.appItem.midY)
    let settings = Scene.menuRowCenter(Scene.settingsItem)
    script.show(hold: settle, cursor: SceneCursor(point: cursorRest))
    script.show(hold: cursorTravel, cursor: SceneCursor(point: item))
    script.show(hold: click, cursor: SceneCursor(point: item, isPressed: true))
    script.show(hold: settle, cursor: SceneCursor(point: item), menu: SceneMenuState())
    script.show(
      hold: closing, cursor: SceneCursor(point: settings),
      menu: SceneMenuState(highlighted: Scene.settingsItem))
    script.show(hold: opening, cursor: SceneCursor(point: cursorRest))
    return script.frames
  }

  static func shortcuts(keys: (Action) -> String?) -> [SceneFrame] {
    var script = SceneScript(
      strip: SceneStrip(styles: styles, widthShares: widthShares, focused: 1))
    script.show(hold: opening)
    script.press(keys(.focusRight)) { $0.focus($0.focused + 1) }
    script.press(keys(.moveLeft)) { $0.moveFocused(by: -1) }
    script.press(keys(.cycleWidth)) { $0.setFocusedWidth(Scene.focusedWidthShare) }
    script.press(keys(.toggleOverview)) { $0.isOverview = true }
    script.press(keys(.toggleOverview)) { $0.isOverview = false }
    script.show(hold: closing)
    return script.frames
  }

  private static func asking(
    _ windows: [SceneWindow], cursor: CGPoint, isPressed: Bool = false, isOn: Bool,
    hold: Duration
  ) -> SceneFrame {
    SceneFrame(
      windows: windows, cursor: SceneCursor(point: cursor, isPressed: isPressed),
      accessToggle: isOn, hold: hold)
  }
}
