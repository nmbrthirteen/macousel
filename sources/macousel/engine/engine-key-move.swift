import StripCore

enum EngineKeyMove: Equatable {
  case drop(DropTarget)
  case shift(HorizontalDirection)

  init?(key: OverviewKey, window: WindowID, columns: EngineColumns) {
    guard let position = columns.position(of: window) else { return nil }
    switch key {
    case .moveWindow(let direction): self.init(direction, from: position, in: columns)
    case .moveWindowToPlace(let place): self.init(place: place, from: position, in: columns)
    default: return nil
    }
  }

  private init?(
    _ direction: Direction, from position: EngineColumns.Position, in columns: EngineColumns
  ) {
    let members = columns.windowIDs[position.column]
    switch direction {
    case .left: self = .shift(.left)
    case .right: self = .shift(.right)
    case .up:
      guard position.row > 0 else { return nil }
      self = .drop(.stack(onto: members[position.row - 1], side: .above))
    case .down:
      guard position.row + 1 < members.count else { return nil }
      self = .drop(.stack(onto: members[position.row + 1], side: .below))
    }
  }

  private init?(place: Int, from position: EngineColumns.Position, in columns: EngineColumns) {
    guard Action.places.contains(place) else { return nil }
    let count = columns.columns.count
    if place == Action.lastPlace {
      self = .drop(.column(position: count))
      return
    }
    let stacked = columns.columns[position.column].windows.count > 1
    guard place <= count + (stacked ? 1 : 0) else { return nil }
    self = .drop(.column(position: place - 1))
  }
}
