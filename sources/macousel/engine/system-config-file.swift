import Foundation

final class SystemConfigFileHandle: ConfigFileHandle {
  private let handle: FileHandle

  init(handle: FileHandle) {
    self.handle = handle
  }

  func write(_ data: Data) throws {
    try handle.seek(toOffset: 0)
    try handle.write(contentsOf: data)
  }

  func truncate(to length: UInt64) throws {
    try handle.truncate(atOffset: length)
  }

  func close() throws {
    try handle.close()
  }
}

struct SystemConfigFileOpener: ConfigFileOpening {
  func open(_ url: URL) throws -> any ConfigFileHandle {
    let manager = FileManager.default
    try manager.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    if !manager.fileExists(atPath: url.path) {
      manager.createFile(atPath: url.path, contents: nil)
    }
    return SystemConfigFileHandle(handle: try FileHandle(forUpdating: url))
  }
}
