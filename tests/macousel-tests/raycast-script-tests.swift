import Foundation
import Testing

@testable import Macousel

@MainActor
struct RaycastScriptTests {
  @Test func scriptOpensTheCommandURLWithRaycastMetadata() {
    let script = RaycastScriptExporter.script(for: .focusLeft)
    #expect(script.hasPrefix("#!/bin/bash\n"))
    #expect(script.contains("# @raycast.title Focus left\n"))
    #expect(script.contains("open -g \"macousel://focus-left\"\n"))
  }

  @Test func exportWritesOneExecutableScriptPerAction() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("macousel-raycast-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }

    #expect(try RaycastScriptExporter.export(to: directory) == Action.allCases.count)
    let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
    #expect(Set(files) == Set(Action.allCases.map(RaycastScriptExporter.fileName)))
    let sample = directory.appendingPathComponent(RaycastScriptExporter.fileName(for: .cycleWidth))
    #expect(FileManager.default.isExecutableFile(atPath: sample.path))
  }
}
