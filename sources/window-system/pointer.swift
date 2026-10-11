import AppKit
import CoreGraphics

public enum Pointer {
  public static var location: CGPoint {
    CGEvent(source: nil)?.location ?? .zero
  }

  public static func warp(to point: CGPoint) {
    CGWarpMouseCursorPosition(point)
    CGAssociateMouseAndMouseCursorPosition(1)
  }

  public static func windowID(at point: CGPoint) -> CGWindowID? {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    else { return nil }
    let ownPID = ProcessInfo.processInfo.processIdentifier
    for info in list {
      guard (info[kCGWindowLayer as String] as? Int) == 0,
        (info[kCGWindowOwnerPID as String] as? pid_t) != ownPID,
        let boundsDictionary = info[kCGWindowBounds as String] as? NSDictionary,
        let bounds = CGRect(dictionaryRepresentation: boundsDictionary),
        bounds.contains(point),
        let number = info[kCGWindowNumber as String] as? UInt32
      else { continue }
      return CGWindowID(number)
    }
    return nil
  }

  public static func bounds(ofWindow window: CGWindowID) -> CGRect? {
    guard
      let list = CGWindowListCopyWindowInfo([.optionIncludingWindow], window) as? [[String: Any]],
      let info = list.first,
      let boundsDictionary = info[kCGWindowBounds as String] as? NSDictionary
    else { return nil }
    return CGRect(dictionaryRepresentation: boundsDictionary)
  }

  public static var isPrimaryButtonDown: Bool {
    NSEvent.pressedMouseButtons & 1 != 0
  }
}
