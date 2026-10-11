import Testing

@testable import Macousel

@MainActor
struct AppVersionTests {
  @Test(arguments: ["0.1.2", "v0.1.2", "V0.1.2", " 0.1.2 "])
  func parsesWithAndWithoutALeadingV(text: String) throws {
    let version = try #require(AppVersion(text))

    #expect(version.components == [0, 1, 2])
    #expect(version.description == "0.1.2")
  }

  @Test func missingComponentsCountAsZero() throws {
    let short = try #require(AppVersion("1.0"))
    let long = try #require(AppVersion("1.0.0"))
    let single = try #require(AppVersion("1"))

    #expect(short == long)
    #expect(single == long)
    #expect(short.hashValue == long.hashValue)
  }

  @Test func comparesComponentsAsNumbers() throws {
    let ten = try #require(AppVersion("0.10.0"))
    let nine = try #require(AppVersion("0.9.9"))
    let patch = try #require(AppVersion("0.9.10"))

    #expect(ten > nine)
    #expect(patch > nine)
    #expect(nine < ten)
  }

  @Test func ordersALongerVersionAboveItsPrefix() throws {
    let base = try #require(AppVersion("1.0"))
    let patched = try #require(AppVersion("1.0.1"))

    #expect(patched > base)
  }

  @Test(arguments: ["", "v", "abc", "1..2", "1.x", "1.2.", "-1.0", "1.0-beta", "99999999999999999999.0"])
  func rejectsGarbage(text: String) {
    #expect(AppVersion(text) == nil)
  }
}
