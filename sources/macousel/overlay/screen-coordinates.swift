import AppKit

extension CGRect {
  var axToCocoa: CGRect {
    guard let primary = NSScreen.screens.first else { return self }
    return CGRect(x: minX, y: primary.frame.height - maxY, width: width, height: height)
  }
}
