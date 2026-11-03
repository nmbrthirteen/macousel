import CoreGraphics

public enum Spaces {
  public static func currentSpace(of display: Display) -> UInt64 {
    CGSManagedDisplayGetCurrentSpace(CGSMainConnectionID(), display.uuid as CFString)
  }

  public static func onScreenWindowIDs() -> Set<CGWindowID> {
    Set(orderedOnScreenWindowIDs())
  }

  public static func orderedOnScreenWindowIDs() -> [CGWindowID] {
    onScreenWindowInfo().compactMap { entry in
      (entry[kCGWindowNumber as String] as? Int).map { CGWindowID($0) }
    }
  }

  // Front to back, normal windows only.
  static func onScreenWindowInfo() -> [[String: Any]] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    else { return [] }
    return info.filter { $0[kCGWindowLayer as String] as? Int == 0 }
  }
}
