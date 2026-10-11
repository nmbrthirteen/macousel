import CoreGraphics

struct SessionMatcher {
  private var unclaimed: [(window: any WindowHandle, title: String)]

  init(_ windows: [any WindowHandle], titles: [CGWindowID: String]) {
    unclaimed = windows.map { ($0, titles[$0.id] ?? "") }
  }

  var remaining: [any WindowHandle] { unclaimed.map(\.window) }

  mutating func claim(_ saved: SavedColumn.Window) -> (any WindowHandle)? {
    let sameApp = unclaimed.indices.filter {
      unclaimed[$0].window.bundleIdentifier == saved.bundleIdentifier
    }
    let exactTitle = sameApp.first { unclaimed[$0].title == saved.title }
    guard let index = exactTitle ?? sameApp.first else { return nil }
    return unclaimed.remove(at: index).window
  }
}
