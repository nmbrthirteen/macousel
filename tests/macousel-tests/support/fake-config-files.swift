import Foundation

@testable import Macousel

@MainActor
final class FakeConfigFileHandle: ConfigFileHandle {
  private(set) var contents: Data
  private(set) var operations: [String] = []
  private(set) var snapshots: [Data] = []
  var failsOnWrite = false

  struct WriteFailure: Error {}

  init(contents: Data) {
    self.contents = contents
  }

  func write(_ data: Data) throws {
    operations.append("write \(data.count)")
    if failsOnWrite { throw WriteFailure() }
    contents = data + Data(contents.dropFirst(data.count))
    snapshots.append(contents)
  }

  func truncate(to length: UInt64) throws {
    operations.append("truncate \(length)")
    contents = Data(contents.prefix(Int(length)))
    snapshots.append(contents)
  }

  func close() throws {
    operations.append("close")
  }
}

@MainActor
final class FakeConfigFiles: ConfigFileOpening {
  let handle: FakeConfigFileHandle
  private(set) var opened: [URL] = []

  init(existing: String = "") {
    handle = FakeConfigFileHandle(contents: Data(existing.utf8))
  }

  func open(_ url: URL) throws -> any ConfigFileHandle {
    opened.append(url)
    return handle
  }
}
