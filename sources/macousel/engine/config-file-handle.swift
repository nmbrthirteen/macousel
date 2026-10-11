import Foundation

protocol ConfigFileHandle: AnyObject {
  func write(_ data: Data) throws
  func truncate(to length: UInt64) throws
  func close() throws
}

protocol ConfigFileOpening {
  func open(_ url: URL) throws -> any ConfigFileHandle
}
