import CoreGraphics

struct SessionMatcher {
  private var unclaimed: [(window: any WindowHandle, titleHash: String)]

  init(_ windows: [any WindowHandle], titles: [CGWindowID: String]) {
    unclaimed = windows.map { ($0, TitleDigest.of(titles[$0.id] ?? "")) }
  }

  var remaining: [any WindowHandle] { unclaimed.map(\.window) }

  mutating func claim(_ saved: SavedColumn.Window) -> (any WindowHandle)? {
    let sameApp = unclaimed.indices.filter {
      unclaimed[$0].window.bundleIdentifier == saved.bundleIdentifier
    }
    let exactTitle = saved.titleHash.flatMap { hash in
      sameApp.first { unclaimed[$0].titleHash == hash }
    }
    guard let index = exactTitle ?? sameApp.first else { return nil }
    return unclaimed.remove(at: index).window
  }
}
