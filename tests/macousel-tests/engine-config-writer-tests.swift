import Foundation
import Testing

@testable import Macousel

@MainActor
struct EngineConfigWriterTests {
  private let url = URL(fileURLWithPath: "/tmp/engine-writer/paneru.toml")

  @Test func writesBeforeTruncatingAndThenCloses() throws {
    let files = FakeConfigFiles(existing: "old old old old")

    try EngineConfigWriter(opener: files).write("new", to: url)

    #expect(files.handle.operations == ["write 3", "truncate 3", "close"])
  }

  @Test func shorterContentLeavesNoTrailingBytes() throws {
    let files = FakeConfigFiles(existing: "0123456789")

    try EngineConfigWriter(opener: files).write("abc", to: url)

    #expect(String(decoding: files.handle.contents, as: UTF8.self) == "abc")
  }

  @Test func longerContentReplacesEverything() throws {
    let files = FakeConfigFiles(existing: "abc")

    try EngineConfigWriter(opener: files).write("0123456789", to: url)

    #expect(String(decoding: files.handle.contents, as: UTF8.self) == "0123456789")
  }

  @Test func theFileIsNeverEmptyBetweenOperations() throws {
    let files = FakeConfigFiles(existing: "previous configuration")

    try EngineConfigWriter(opener: files).write("next", to: url)

    #expect(!files.handle.snapshots.isEmpty)
    #expect(files.handle.snapshots.allSatisfy { !$0.isEmpty })
  }

  @Test func closesTheHandleWhenTheWriteFails() {
    let files = FakeConfigFiles(existing: "previous")
    files.handle.failsOnWrite = true

    #expect(throws: FakeConfigFileHandle.WriteFailure.self) {
      try EngineConfigWriter(opener: files).write("next", to: url)
    }
    #expect(files.handle.operations.last == "close")
    #expect(String(decoding: files.handle.contents, as: UTF8.self) == "previous")
  }

  @Test func theSystemOpenerKeepsTheSameFileAndShrinksIt() throws {
    let directory = try TemporaryDirectory()
    defer { directory.remove() }
    let file = directory.url.appendingPathComponent("nested/paneru.toml")
    let writer = EngineConfigWriter(opener: SystemConfigFileOpener())
    try writer.write(String(repeating: "x", count: 500), to: file)
    let before = try FileManager.default.attributesOfItem(atPath: file.path)[.systemFileNumber] as? UInt64

    try writer.write("short", to: file)

    #expect(try String(contentsOf: file, encoding: .utf8) == "short")
    let after = try FileManager.default.attributesOfItem(atPath: file.path)[.systemFileNumber] as? UInt64
    #expect(before != nil)
    #expect(before == after)
  }
}
