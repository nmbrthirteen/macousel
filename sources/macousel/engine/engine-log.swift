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

  func lastLines(_ count: Int) -> String {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
    return text.split(separator: "\n", omittingEmptySubsequences: true).suffix(count)
      .joined(separator: "\n")
  }

  private func rotateIfNeeded(_ manager: FileManager) {
    let size = (try? manager.attributesOfItem(atPath: url.path)[.size] as? UInt64) ?? nil
    guard let size, size >= Self.rotationSize else { return }
    try? manager.removeItem(at: previous)
    try? manager.moveItem(at: url, to: previous)
  }
}
