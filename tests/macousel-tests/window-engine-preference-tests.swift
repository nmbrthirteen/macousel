import Foundation
import Testing

@testable import Macousel

@MainActor
struct WindowEnginePreferenceTests {
  private func decode(_ json: String) throws -> Preferences {
    try JSONDecoder().decode(Preferences.self, from: Data(json.utf8))
  }

  @Test func defaultsToPaneru() {
    #expect(Preferences().engine == .paneru)
  }

  @Test func settingsWithoutAnEngineUsePaneru() throws {
    #expect(try decode("{}").engine == .paneru)
  }

  @Test func decodesTheBuiltInEngine() throws {
    #expect(try decode(#"{"engine":"builtIn"}"#).engine == .builtIn)
  }

  @Test func anUnknownEngineFallsBackToPaneru() throws {
    #expect(try decode(#"{"engine":"future"}"#).engine == .paneru)
    #expect(try decode(#"{"engine":7}"#).engine == .paneru)
  }

  @Test func roundTripsThroughEncoding() throws {
    var preferences = Preferences()
    preferences.engine = .builtIn

    let data = try JSONEncoder().encode(preferences)

    #expect(try JSONDecoder().decode(Preferences.self, from: data).engine == .builtIn)
  }

  @Test func titlesAndSummariesAreShort() {
    #expect(WindowEngine.allCases.map(\.title) == ["Paneru", "Built-in"])
    for engine in WindowEngine.allCases {
      #expect(engine.summary.hasSuffix("."))
      #expect(engine.summary.filter { $0 == "." }.count == 1)
    }
  }
}
