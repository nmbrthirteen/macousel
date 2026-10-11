import CoreGraphics
import WindowSystem

extension Display {
  static let menuBarHeight: CGFloat = 24

  static func fake(
    id: CGDirectDisplayID = 1, originX: CGFloat = 0, width: CGFloat = 1000, height: CGFloat = 800
  ) -> Display {
    Display(
      id: id,
      uuid: "display-\(id)",
      name: "Display \(id)",
      frame: CGRect(x: originX, y: 0, width: width, height: height),
      visibleFrame: CGRect(
        x: originX, y: menuBarHeight, width: width, height: height - menuBarHeight),
      isMain: id == 1)
  }

  static let leftOfPair = Display.fake(id: 1)
  static let rightOfPair = Display.fake(id: 2, originX: 1000)
}
