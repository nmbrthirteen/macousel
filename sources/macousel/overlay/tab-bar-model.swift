import CoreGraphics
import StripCore

struct TabBarModel: Equatable, Identifiable {
  struct Tab: Equatable, Identifiable {
    var id: WindowID
    var title: String
    var isActive: Bool
  }

  var id: WindowID
  var frame: CGRect
  var tabs: [Tab]
}
