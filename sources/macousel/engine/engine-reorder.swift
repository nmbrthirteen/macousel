import StripCore

final class EngineReorder {
  static let polls = 10
  static let interval = Duration.milliseconds(100)

  private let commands: any EngineCommanding
  private let sleep: (Duration) async throws -> Void
  private var latest: EngineSnapshot?
  private(set) var isRunning = false

  init(commands: any EngineCommanding, sleep: @escaping (Duration) async throws -> Void) {
    self.commands = commands
    self.sleep = sleep
  }

  func move(_ window: WindowID, to target: DropTarget) async -> EngineSnapshot? {
    await execute { columns in EngineReorderPlan(columns: columns, moving: window, to: target) }
  }

  func shift(_ window: WindowID, toward direction: HorizontalDirection) async -> EngineSnapshot? {
    await execute { columns in
      EngineReorderPlan(columns: columns, moving: window, shifting: direction)
    }
  }

  private func execute(_ makePlan: ([[WindowID]]) -> EngineReorderPlan?) async -> EngineSnapshot? {
    guard !isRunning else { return nil }
    isRunning = true
    defer { isRunning = false }
    guard let snapshot = await commands.fetchSnapshot() else { return nil }
    latest = snapshot
    let columns = snapshot.tiledColumns
    if let plan = makePlan(columns.windowIDs), !plan.steps.isEmpty,
      await focus(plan.source, in: columns)
    {
      await run(plan.steps, window: columns.windowIDs[plan.source.column][plan.source.row])
    }
    return latest
  }

  private func run(_ steps: [EngineReorderPlan.Step], window: WindowID) async {
    for step in steps {
      guard await perform(step, window: window) else { return }
    }
  }

  private func focus(_ source: EngineColumns.Position, in columns: EngineColumns) async -> Bool {
    let members = columns.windowIDs[source.column]
    if latest?.focusedWindowID == members[source.row] { return true }
    await commands.send(["window", "focus", "\(source.column + 1)"])
    for row in 0...source.row {
      if row > 0 { await commands.send(["window", "focus", "south"]) }
      let expected = members[row]
      guard await wait(until: { $0.focusedWindowID == expected }) else { return false }
    }
    return true
  }

  private func perform(_ step: EngineReorderPlan.Step, window: WindowID) async -> Bool {
    switch step {
    case .unstack: await unstack(window)
    case .moveColumn(let destination): await moveColumn(of: window, to: destination)
    case .stack(let target): await stack(window, onto: target)
    case .moveRow(let delta): await moveRow(of: window, by: delta)
    }
  }

  private func unstack(_ window: WindowID) async -> Bool {
    await commands.send(["window", "unstack"])
    return await wait { snapshot in
      let columns = snapshot.tiledColumns
      guard let column = columns.columnIndex(of: window) else { return false }
      return columns.columns[column].windows.count == 1
    }
  }

  private func stack(_ window: WindowID, onto target: WindowID) async -> Bool {
    await commands.send(["window", "stack"])
    return await wait { snapshot in
      let columns = snapshot.tiledColumns
      guard let column = columns.columnIndex(of: window) else { return false }
      return column == columns.columnIndex(of: target)
    }
  }

  private func moveColumn(of window: WindowID, to destination: Int) async -> Bool {
    while let current = latest?.tiledColumns.columnIndex(of: window), current != destination {
      let last = (latest?.tiledColumns.columns.count ?? 0) - 1
      let (words, expected) = columnSwap(from: current, to: destination, last: last)
      await commands.send(words)
      let arrived = await wait { $0.tiledColumns.columnIndex(of: window) == expected }
      guard arrived else { return false }
    }
    return latest?.tiledColumns.columnIndex(of: window) == destination
  }

  private func columnSwap(from current: Int, to destination: Int, last: Int)
    -> (words: [String], expected: Int)
  {
    if destination == last { return (["window", "swap", "last"], destination) }
    if destination == 0 { return (["window", "swap", "first"], destination) }
    if destination > current { return (["window", "swap", "east"], current + 1) }
    return (["window", "swap", "west"], current - 1)
  }

  private func moveRow(of window: WindowID, by delta: Int) async -> Bool {
    let direction = delta < 0 ? "north" : "south"
    let unit = delta < 0 ? -1 : 1
    for _ in 0..<abs(delta) {
      guard let row = latest?.tiledColumns.row(of: window) else { return false }
      await commands.send(["window", "swap", direction])
      let moved = await wait { $0.tiledColumns.row(of: window) == row + unit }
      guard moved else { return false }
    }
    return true
  }

  private func wait(until condition: (EngineSnapshot) -> Bool) async -> Bool {
    for _ in 0..<Self.polls {
      if let fetched = await commands.fetchSnapshot() {
        latest = fetched
        if condition(fetched) { return true }
      }
      do {
        try await sleep(Self.interval)
      } catch {
        return false
      }
    }
    return false
  }
}
