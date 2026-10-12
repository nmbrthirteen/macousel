import StripCore

final class EngineReorder {
  private let commands: any EngineCommanding
  private let sleep: (Duration) async throws -> Void
  private let now: () -> ContinuousClock.Instant
  private var latest: EngineSnapshot?
  private(set) var isRunning = false

  init(
    commands: any EngineCommanding, sleep: @escaping (Duration) async throws -> Void,
    now: @escaping () -> ContinuousClock.Instant = { ContinuousClock.now }
  ) {
    self.commands = commands
    self.sleep = sleep
    self.now = now
  }

  func move(_ window: WindowID, to target: DropTarget) async -> EngineReorderOutcome {
    await execute { columns in EngineReorderPlan(columns: columns, moving: window, to: target) }
  }

  func shift(_ window: WindowID, toward direction: HorizontalDirection) async
    -> EngineReorderOutcome
  {
    await execute { columns in
      EngineReorderPlan(columns: columns, moving: window, shifting: direction)
    }
  }

  func focus(_ window: WindowID) async {
    guard !isRunning else { return }
    isRunning = true
    defer { isRunning = false }
    guard let snapshot = await commands.fetchSnapshot() else { return }
    latest = snapshot
    let columns = snapshot.tiledColumns
    guard let position = columns.position(of: window) else { return }
    _ = await focus(position, in: columns)
  }

  private func execute(_ makePlan: ([[WindowID]]) -> EngineReorderPlan?) async
    -> EngineReorderOutcome
  {
    guard !isRunning else { return .busy }
    isRunning = true
    defer { isRunning = false }
    guard let snapshot = await commands.fetchSnapshot() else { return .unavailable }
    latest = snapshot
    let columns = snapshot.tiledColumns
    guard let plan = makePlan(columns.windowIDs), !plan.steps.isEmpty else {
      return .nothingToDo(snapshot)
    }
    guard await focus(plan.source, in: columns) else { return .aborted(step: "focus", latest) }
    let window = columns.windowIDs[plan.source.column][plan.source.row]
    if let failed = await run(plan.steps, window: window) {
      return .aborted(step: failed.name, latest)
    }
    return .completed(latest ?? snapshot)
  }

  private func run(_ steps: [EngineReorderPlan.Step], window: WindowID) async
    -> EngineReorderPlan.Step?
  {
    for step in steps {
      guard await perform(step, window: window) else { return step }
    }
    return nil
  }

  private func focus(_ source: EngineColumns.Position, in columns: EngineColumns) async -> Bool {
    let members = columns.windowIDs[source.column]
    if latest?.focusedWindowID == members[source.row] { return true }
    await commands.send(["window", "focus", "\(source.column + 1)"])
    for row in 0...source.row {
      if row > 0 {
        guard hasNeighbour(of: members[row - 1], below: true) else { return false }
        await commands.send(["window", "focus", "south"])
      }
      let expected = members[row]
      guard await wait(until: { $0.focusedWindowID == expected }) else { return false }
    }
    return true
  }

  private func holdsFocus(on window: WindowID) async -> Bool {
    if latest?.focusedWindowID == window { return true }
    guard let snapshot = await commands.fetchSnapshot() else { return false }
    latest = snapshot
    let columns = snapshot.tiledColumns
    guard let position = columns.position(of: window) else { return false }
    return await focus(position, in: columns)
  }

  private func send(_ words: [String], keepingFocusOn window: WindowID) async -> Bool {
    guard await holdsFocus(on: window) else { return false }
    await commands.send(words)
    return true
  }

  private func hasNeighbour(of window: WindowID, below: Bool) -> Bool {
    guard let position = latest?.tiledColumns.position(of: window),
      let members = latest?.tiledColumns.windowIDs[position.column]
    else { return false }
    return below ? position.row + 1 < members.count : position.row > 0
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
    guard await send(["window", "unstack"], keepingFocusOn: window) else { return false }
    return await wait { snapshot in
      let columns = snapshot.tiledColumns
      guard let column = columns.columnIndex(of: window) else { return false }
      return columns.columns[column].windows.count == 1
    }
  }

  private func stack(_ window: WindowID, onto target: WindowID) async -> Bool {
    guard await send(["window", "stack"], keepingFocusOn: window) else { return false }
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
      guard await send(words, keepingFocusOn: window) else { return false }
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
      guard await holdsFocus(on: window), let row = latest?.tiledColumns.row(of: window),
        hasNeighbour(of: window, below: unit > 0)
      else { return false }
      await commands.send(["window", "swap", direction])
      let moved = await wait { $0.tiledColumns.row(of: window) == row + unit }
      guard moved else { return false }
    }
    return true
  }

  private func wait(until condition: (EngineSnapshot) -> Bool) async -> Bool {
    let poll = EnginePoll(commands: commands, sleep: sleep, now: now)
    return await poll.until(condition, observing: { self.latest = $0 })
  }
}
