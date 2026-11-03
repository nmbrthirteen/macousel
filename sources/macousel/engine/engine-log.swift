import Foundation

nonisolated struct EngineLog: Sendable {
  static let rotationSize: UInt64 = 1_048_576

  let url: URL

  var previous: URL { url.appendingPathExtension("1") }

  func append(_ data: Data) {
    let manager = FileManager.default
    try? manager.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    rotateIfNeeded(manager)
    if !manager.fileExists(atPath: url.path) { manager.createFile(atPath: url.path, contents: nil) }
    guard let handle = try? FileHandle(forWritingTo: url) else { return }
    defer { try? handle.close() }
    _ = try? handle.seekToEnd()
    try? handle.write(contentsOf: data)
  }

  // Reads up to two megabytes, so it stays off the main actor. A fresh rotation leaves the
  // current file short, and the rest of the tail comes from the previous one.
  @concurrent func lastLines(_ count: Int) async -> String {
    let current = Self.lines(in: url)
    let missing = count - current.count
    let earlier = missing > 0 ? Self.lines(in: previous).suffix(missing) : []
    return (earlier + current.suffix(count)).joined(separator: "\n")
  }

  private static func lines(in file: URL) -> [Substring] {
    guard let text = try? String(contentsOf: file, encoding: .utf8) else { return [] }
    return text.split(separator: "\n", omittingEmptySubsequences: true)
  }

  private func rotateIfNeeded(_ manager: FileManager) {
    let size = (try? manager.attributesOfItem(atPath: url.path)[.size] as? UInt64) ?? nil
    guard let size, size >= Self.rotationSize else { return }
    try? manager.removeItem(at: previous)
    try? manager.moveItem(at: url, to: previous)
  }
}
