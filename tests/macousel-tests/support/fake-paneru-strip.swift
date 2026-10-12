@testable import Macousel

@MainActor
final class FakePaneruStrip {
  private struct Pending {
    var words: [String]
    var delay: Int
  }

  var columns: [[Int32]]
  var focused: Int32?
  var lag = 0
  var ignoresCommands = false
  private var pending: [Pending] = []

  init(columns: [[Int32]], focused: Int32? = nil) {
    self.columns = columns
    self.focused = focused ?? columns.first?.first
  }

  var snapshot: EngineSnapshot {
    let windows = columns.enumerated().flatMap { column, members in
      members.enumerated().map { row, identifier in
        EngineWindow(
          windowId: identifier, bundleId: "app.\(identifier)", appName: "App \(identifier)",
          title: "Window \(identifier)", focused: identifier == focused, displayId: 1,
          frame: EngineWindow.Frame(x: column * 1000, y: row * 500, width: 960, height: 400))
      }
    }
    return EngineFixtures.snapshot(of: windows)
  }

  func receive(_ words: [String]) {
    guard !ignoresCommands else { return }
    pending.append(Pending(words: words, delay: lag))
  }

  func advance() {
    var waiting: [Pending] = []
    for entry in pending {
      if entry.delay <= 0 {
        apply(entry.words)
      } else {
        waiting.append(Pending(words: entry.words, delay: entry.delay - 1))
      }
    }
    pending = waiting
  }

  private func apply(_ words: [String]) {
    guard words.first == "window", words.count >= 2, let focused,
      let column = columns.firstIndex(where: { $0.contains(focused) }),
      let row = columns[column].firstIndex(of: focused)
    else { return }
    switch (words[1], words.count > 2 ? words[2] : "") {
    case ("focus", "south"): focusRow(row + 1, in: column)
    case ("focus", let number): focusColumn(Int(number).map { $0 - 1 })
    case ("swap", "north"): swapRows(row, row - 1, in: column)
    case ("swap", "south"): swapRows(row, row + 1, in: column)
    case ("swap", "west"): swapColumns(column, column - 1)
    case ("swap", "east"): swapColumns(column, column + 1)
    case ("swap", "first"): columns.insert(columns.remove(at: column), at: 0)
    case ("swap", "last"): columns.append(columns.remove(at: column))
    case ("stack", _): stack(column)
    case ("unstack", _): unstack(column, row)
    default: break
    }
  }

  private func focusRow(_ row: Int, in column: Int) {
    if columns[column].indices.contains(row) { focused = columns[column][row] }
  }

  private func focusColumn(_ index: Int?) {
    if let index, columns.indices.contains(index) { focused = columns[index].first }
  }

  private func swapRows(_ first: Int, _ second: Int, in column: Int) {
    if columns[column].indices.contains(second) { columns[column].swapAt(first, second) }
  }

  private func swapColumns(_ first: Int, _ second: Int) {
    if columns.indices.contains(second) { columns.swapAt(first, second) }
  }

  private func stack(_ column: Int) {
    guard column > 0 else { return }
    let members = columns.remove(at: column)
    columns[column - 1].append(contentsOf: members)
  }

  private func unstack(_ column: Int, _ row: Int) {
    guard columns[column].count > 1 else { return }
    let popped = columns[column].remove(at: row)
    columns.insert([popped], at: column + 1)
  }
}
