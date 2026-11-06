import Foundation
import os

// FileHandle.bytes hands over one byte per await, a queue hop for every byte of a snapshot.
// Reading whole chunks and splitting them costs one hop per line.
nonisolated enum LineStream {
  static func lines(of handle: FileHandle) -> AsyncStream<String> {
    AsyncStream { continuation in
      let pending = OSAllocatedUnfairLock(initialState: Data())
      handle.readabilityHandler = { handle in
        let chunk = handle.availableData
        guard !chunk.isEmpty else {
          handle.readabilityHandler = nil
          continuation.finish()
          return
        }
        let lines = pending.withLock { buffer in split(appending: chunk, to: &buffer) }
        lines.forEach { continuation.yield($0) }
      }
      continuation.onTermination = { _ in handle.readabilityHandler = nil }
    }
  }

  static func split(appending chunk: Data, to buffer: inout Data) -> [String] {
    buffer.append(chunk)
    var lines: [String] = []
    var start = buffer.startIndex
    while let end = buffer[start...].firstIndex(of: UInt8(ascii: "\n")) {
      lines.append(String(decoding: buffer[start..<end], as: UTF8.self))
      start = buffer.index(after: end)
    }
    buffer.removeSubrange(buffer.startIndex..<start)
    return lines
  }
}
