import StripCore

nonisolated struct EngineReorderPlan: Equatable, Sendable {
  enum Step: Equatable, Sendable {
    case unstack
    case moveColumn(to: Int)
    case stack(onto: WindowID)
    case moveRow(by: Int)
  }

  let source: EngineColumns.Position
  let steps: [Step]

  init?(columns: [[WindowID]], moving window: WindowID, to target: DropTarget) {
    guard let source = Self.position(of: window, in: columns) else { return nil }
    let steps: [Step]?
    switch target {
    case .nowhere: steps = nil
    case .column(let position): steps = Self.columnSteps(columns, window, source, position)
    case .stack(let onto, let side): steps = Self.stackSteps(columns, window, source, onto, side)
    }
    guard let steps else { return nil }
    self.source = source
    self.steps = steps
  }

  init?(columns: [[WindowID]], moving window: WindowID, shifting direction: HorizontalDirection) {
    guard let source = Self.position(of: window, in: columns) else { return nil }
    let destination = direction == .left ? source.column - 1 : source.column + 1
    guard columns.indices.contains(destination) else { return nil }
    self.source = source
    steps = [.moveColumn(to: destination)]
  }

  private static func position(of window: WindowID, in columns: [[WindowID]])
    -> EngineColumns.Position?
  {
    for (column, members) in columns.enumerated() {
      if let row = members.firstIndex(of: window) {
        return EngineColumns.Position(column: column, row: row)
      }
    }
    return nil
  }

  private static func isolated(
    _ columns: [[WindowID]], _ window: WindowID, _ source: EngineColumns.Position
  ) -> (layout: [[WindowID]], column: Int, steps: [Step]) {
    guard columns[source.column].count > 1 else { return (columns, source.column, []) }
    var layout = columns
    layout[source.column].remove(at: source.row)
    layout.insert([window], at: source.column + 1)
    return (layout, source.column + 1, [.unstack])
  }

  private static func columnSteps(
    _ columns: [[WindowID]], _ window: WindowID, _ source: EngineColumns.Position, _ position: Int
  ) -> [Step] {
    let alone = isolated(columns, window, source)
    let destination = min(max(position, 0), alone.layout.count - 1)
    guard destination != alone.column else { return alone.steps }
    return alone.steps + [.moveColumn(to: destination)]
  }

  private static func stackSteps(
    _ columns: [[WindowID]], _ window: WindowID, _ source: EngineColumns.Position,
    _ target: WindowID, _ side: VerticalNeighbor
  ) -> [Step]? {
    guard window != target, let destination = position(of: target, in: columns) else {
      return nil
    }
    var row = side == .above ? destination.row : destination.row + 1
    if source.column == destination.column {
      if source.row < destination.row { row -= 1 }
      return row == source.row ? [] : [.moveRow(by: row - source.row)]
    }
    let alone = isolated(columns, window, source)
    guard let targetColumn = alone.layout.firstIndex(where: { $0.contains(target) }) else {
      return nil
    }
    var steps = alone.steps
    let beside = alone.column < targetColumn ? targetColumn : targetColumn + 1
    if beside != alone.column { steps.append(.moveColumn(to: beside)) }
    steps.append(.stack(onto: target))
    let bottom = alone.layout[targetColumn].count
    if row != bottom { steps.append(.moveRow(by: row - bottom)) }
    return steps
  }
}
