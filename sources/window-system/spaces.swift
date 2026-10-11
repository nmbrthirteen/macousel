import CoreGraphics

public enum Spaces {
  public static func currentSpace(of display: Display) -> UInt64 {
    CGSManagedDisplayGetCurrentSpace(CGSMainConnectionID(), display.uuid as CFString)
  }

  public static func onScreenWindowIDs() -> Set<CGWindowID> {
    Set(orderedOnScreenWindowIDs())
  }

  public static func orderedOnScreenWindowIDs() -> [CGWindowID] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    else { return [] }
    var ids: [CGWindowID] = []
    for entry in info {
      guard entry[kCGWindowLayer as String] as? Int == 0,
        let number = entry[kCGWindowNumber as String] as? Int
      else { continue }
      ids.append(CGWindowID(number))
    }
    return ids
  }
}
