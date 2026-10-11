import StripCore

struct MinimapSnapshot: Equatable {
  struct Row: Equatable {
    var window: WindowID
    var bundleIdentifier: String?
    var height: Double
  }

  struct Column: Equatable {
    var x: Double
    var width: Double
    var rows: [Row]
    var activeRow: Int
    var isTabbed: Bool
    var isFocused: Bool
  }

  static let empty = MinimapSnapshot(
    columns: [], contentWidth: 0, viewportOffset: 0, viewportWidth: 0, animationResponse: nil)

  var columns: [Column]
  var contentWidth: Double
  var viewportOffset: Double
  var viewportWidth: Double
  var animationResponse: Double?
}
