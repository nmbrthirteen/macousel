import AppKit
import CoreGraphics

public struct Display: Equatable, Sendable {
  public let id: CGDirectDisplayID
  public let uuid: String
  public let name: String
  public let frame: CGRect
  public let visibleFrame: CGRect
  public let isMain: Bool

  public enum Side: Sendable { case left, right, below }

  nonisolated public init(
    id: CGDirectDisplayID, uuid: String, name: String, frame: CGRect, visibleFrame: CGRect,
    isMain: Bool
  ) {
    self.id = id
    self.uuid = uuid
    self.name = name
    self.frame = frame
    self.visibleFrame = visibleFrame
    self.isMain = isMain
  }

  public static func all() -> [Display] {
    let screens = NSScreen.screens
    guard let primary = screens.first else { return [] }
    let primaryHeight = primary.frame.height

    let displays = screens.compactMap { screen -> Display? in
      guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
        as? NSNumber
      else { return nil }
      let id = CGDirectDisplayID(number.uint32Value)
      return Display(
        id: id,
        uuid: uuidString(for: id),
        name: screen.localizedName,
        frame: axRect(screen.frame, primaryHeight: primaryHeight),
        visibleFrame: axRect(screen.visibleFrame, primaryHeight: primaryHeight),
        isMain: CGDisplayIsMain(id) != 0
      )
    }
    return displays.sorted { $0.frame.minX < $1.frame.minX }
  }

  public func hasNeighbor(_ side: Side, among displays: [Display]) -> Bool {
    let tolerance: CGFloat = 1
    return displays.contains { other in
      guard other.id != id else { return false }
      switch side {
      case .left:
        return abs(other.frame.maxX - frame.minX) <= tolerance
          && Self.overlap(other.frame.minY, other.frame.maxY, frame.minY, frame.maxY)
      case .right:
        return abs(other.frame.minX - frame.maxX) <= tolerance
          && Self.overlap(other.frame.minY, other.frame.maxY, frame.minY, frame.maxY)
      case .below:
        return abs(other.frame.minY - frame.maxY) <= tolerance
          && Self.overlap(other.frame.minX, other.frame.maxX, frame.minX, frame.maxX)
      }
    }
  }

  private static func overlap(_ a0: CGFloat, _ a1: CGFloat, _ b0: CGFloat, _ b1: CGFloat) -> Bool {
    min(a1, b1) - max(a0, b0) > 0
  }

  private static func axRect(_ cocoa: CGRect, primaryHeight: CGFloat) -> CGRect {
    CGRect(
      x: cocoa.minX, y: primaryHeight - cocoa.maxY, width: cocoa.width, height: cocoa.height)
  }

  private static func uuidString(for id: CGDirectDisplayID) -> String {
    guard let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue(),
      let string = CFUUIDCreateString(nil, uuid)
    else { return "" }
    return string as String
  }
}
