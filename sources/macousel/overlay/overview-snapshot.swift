import CoreGraphics
import StripCore

struct OverviewSnapshot: Equatable {
  struct Card: Equatable {
    var window: WindowID
    var title: String
    var bundleIdentifier: String?
    var heightShare: Double
    var frame: CGRect? = nil
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
  var allowsResize = true

  func placing(_ frame: (Card) -> CGRect?) -> OverviewSnapshot {
    var placed = self
    for column in placed.columns.indices {
      for row in placed.columns[column].cards.indices {
        let card = placed.columns[column].cards[row]
        placed.columns[column].cards[row].frame = frame(card) ?? card.frame
      }
    }
    return placed
  }
}
