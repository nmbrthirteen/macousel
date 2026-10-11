import StripCore

struct OverviewSnapshot: Equatable {
  struct Card: Equatable {
    var window: WindowID
    var title: String
    var bundleIdentifier: String?
    var heightShare: Double
  }

  struct Column: Equatable {
    var width: Double
    var cards: [Card]
    var isTabbed = false
  }

  static let empty = OverviewSnapshot(columns: [], stripHeight: 0, selection: nil)

  var columns: [Column]
  var stripHeight: Double
  var selection: WindowID?
  var usableWidth = 0.0
  var innerGap = 0.0
  var presetWidths: [Double] = []
  var springResponse: Double?
}
