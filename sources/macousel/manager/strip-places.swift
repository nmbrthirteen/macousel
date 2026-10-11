import StripCore

extension Strip {
  mutating func focusPlace(_ place: Int) -> Bool {
    guard let index = columnIndex(forPlace: place) else { return false }
    return focusColumn(index)
  }

  mutating func moveFocusedToPlace(_ place: Int) -> Bool {
    guard Action.places.contains(place), let focused = focusedColumn else { return false }
    if place == Action.lastPlace { return moveFocusedWindow(toColumn: columns.count) }
    let columnsAfterMove = columns.count + (columns[focused].windows.count > 1 ? 1 : 0)
    guard place <= columnsAfterMove else { return false }
    return moveFocusedWindow(toColumn: place - 1)
  }

  mutating func moveFocusedWindow(toColumn index: Int) -> Bool {
    guard let window = focusedWindow else { return false }
    let before = self
    move(window, toColumn: index)
    return self != before
  }

  private func columnIndex(forPlace place: Int) -> Int? {
    guard Action.places.contains(place), !columns.isEmpty else { return nil }
    if place == Action.lastPlace { return columns.count - 1 }
    return columns.indices.contains(place - 1) ? place - 1 : nil
  }
}
