import CoreGraphics
import Foundation
import StripCore
import WindowSystem

struct SavedColumn: Codable {
  struct Window: Codable {
    var bundleIdentifier: String?
    var title: String
  }

  var width: ColumnWidth
  var display: ColumnDisplay
  var windows: [Window]
  var heightWeights: [Double]?
  var isFullWidth: Bool?
}

enum SessionStore {
  private static let key = "session"

  static func load() -> [String: [SavedColumn]] {
    guard let data = UserDefaults.standard.data(forKey: key),
      let session = try? JSONDecoder().decode([String: [SavedColumn]].self, from: data)
    else { return [:] }
    return session
  }

  static func save(_ stripsByDisplay: [String: Strip], windows: [CGWindowID: ManagedWindow]) {
    let session = stripsByDisplay.mapValues { strip in
      strip.columns.map { SavedColumn($0, windows: windows) }
    }
    guard let data = try? JSONEncoder().encode(session) else { return }
    UserDefaults.standard.set(data, forKey: key)
  }
}

extension SavedColumn {
  init(_ column: Column, windows: [CGWindowID: ManagedWindow]) {
    self.init(
      width: column.width,
      display: column.display,
      windows: column.windows.compactMap { windows[$0.rawValue].map(Window.init) },
      heightWeights: column.heightWeights,
      isFullWidth: column.isFullWidth)
  }
}

extension SavedColumn.Window {
  init(_ window: ManagedWindow) {
    self.init(bundleIdentifier: window.bundleIdentifier, title: window.title)
  }
}

struct SessionMatcher {
  private var unclaimed: [(window: ManagedWindow, title: String)]

  init(_ windows: [ManagedWindow]) {
    unclaimed = windows.map { ($0, $0.title) }
  }

  var remaining: [ManagedWindow] { unclaimed.map(\.window) }

  mutating func claim(_ saved: SavedColumn.Window) -> ManagedWindow? {
    let sameApp = unclaimed.indices.filter {
      unclaimed[$0].window.bundleIdentifier == saved.bundleIdentifier
    }
    let exactTitle = sameApp.first { unclaimed[$0].title == saved.title }
    guard let index = exactTitle ?? sameApp.first else { return nil }
    return unclaimed.remove(at: index).window
  }
}

extension Strip {
  mutating func restore(_ saved: [SavedColumn], from windows: [ManagedWindow]) -> [ManagedWindow] {
    var matcher = SessionMatcher(windows)
    for column in saved {
      let members = column.windows.compactMap { matcher.claim($0) }.map { WindowID($0) }
      restoreColumn(of: members, like: column)
    }
    return matcher.remaining
  }

  private mutating func restoreColumn(of members: [WindowID], like saved: SavedColumn) {
    guard let first = members.first else { return }
    append(first, width: saved.width)
    for member in members.dropFirst() {
      append(member, width: saved.width)
      focus(member)
      stackFocused(into: .left)
    }
    focus(first)
    if let weights = saved.heightWeights {
      setHeightWeights(weights, ofColumnContaining: first)
    }
    if saved.display == .tabbed && members.count > 1 {
      toggleTabbed()
    }
    if saved.isFullWidth == true {
      toggleFullWidth()
    }
  }
}
