import CoreGraphics
import Foundation
import StripCore
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct SessionTitleHashTests {
  private struct OldWindow: Encodable {
    var bundleIdentifier: String?
    var title: String
  }

  private struct OldColumn: Encodable {
    var width: ColumnWidth
    var display: ColumnDisplay
    var windows: [OldWindow]
  }

  @Test func theDigestIsSixteenLowercaseHexCharacters() {
    let digest = TitleDigest.of("Quarterly plan")

    #expect(digest.count == 16)
    #expect(digest.allSatisfy { $0.isHexDigit && !$0.isUppercase })
    #expect(digest == TitleDigest.of("Quarterly plan"))
    #expect(digest != TitleDigest.of("Quarterly plan 2"))
  }

  @Test func theSavedSessionHoldsNoPlainTitle() throws {
    let suite = try IsolatedDefaults()
    let fixture = try ControllerFixture(suite: suite)
    fixture.open(1, app: .editor, title: "Salary review draft", atX: 100, activating: true)
    fixture.open(2, app: .browser, title: "Bank statement", atX: 400)
    fixture.launch()

    fixture.quit()

    let text = String(decoding: try #require(suite.defaults.data(forKey: "session")), as: UTF8.self)
    #expect(!text.contains("Salary"))
    #expect(!text.contains("Bank"))
    #expect(text.contains(TitleDigest.of("Salary review draft")))
  }

  @Test func windowsAreMatchedByTheHashOfTheirTitle() throws {
    let suite = try IsolatedDefaults()
    let first = try ControllerFixture(suite: suite) { $0.layout.defaultWidth = 0.25 }
    first.open(1, app: .editor, title: "Notes", atX: 100, activating: true)
    first.open(2, app: .editor, title: "Draft", atX: 400)
    first.launch()
    first.manager.perform(.cycleWidth)
    first.quit()

    let second = try ControllerFixture(suite: suite) { $0.layout.defaultWidth = 0.25 }
    let draft = second.open(11, app: .editor, title: "Draft", atX: 100)
    let notes = second.open(12, app: .editor, title: "Notes", atX: 400)
    second.launch()

    var expected = ExpectedStrip(columns: [12, 11], fraction: 0.25)
    let config = expected.config
    expected.focus(12)
    expected.strip.cycleWidth(config: config)
    #expect(second.frames(of: [notes, draft]) == expected.frames)
  }

  @Test func sessionsSavedWithPlainTitlesStillDecodeAndMatchByAppAlone() throws {
    let suite = try IsolatedDefaults()
    let old: [String: [OldColumn]] = [
      Display.fake().uuid: [
        OldColumn(
          width: .fraction(0.25), display: .stacked,
          windows: [OldWindow(bundleIdentifier: "test.editor", title: "Notes")]),
        OldColumn(
          width: .fraction(0.75), display: .stacked,
          windows: [OldWindow(bundleIdentifier: "test.editor", title: "Draft")]),
      ]
    ]
    suite.defaults.set(try JSONEncoder().encode(old), forKey: "session")
    #expect(SessionStore(defaults: suite.defaults).load().values.flatMap { $0 }.count == 2)
    let fixture = try ControllerFixture(suite: suite)
    let left = fixture.open(11, app: .editor, title: "Draft", atX: 100, activating: true)
    let right = fixture.open(12, app: .editor, title: "Notes", atX: 400)

    fixture.launch()

    var expected = ExpectedStrip()
    expected.append(11, .fraction(0.25))
    expected.append(12, .fraction(0.75))
    expected.focus(11)
    #expect(fixture.frames(of: [left, right]) == expected.frames)
  }

  @Test func anOldFormatSessionIsRewrittenWithHashesOnTheNextSave() throws {
    let suite = try IsolatedDefaults()
    let old: [String: [OldColumn]] = [
      Display.fake().uuid: [
        OldColumn(
          width: .fraction(0.5), display: .stacked,
          windows: [OldWindow(bundleIdentifier: "test.editor", title: "Private notes")])
      ]
    ]
    suite.defaults.set(try JSONEncoder().encode(old), forKey: "session")
    let fixture = try ControllerFixture(suite: suite)
    fixture.open(1, app: .editor, title: "Private notes", atX: 100, activating: true)
    fixture.launch()

    fixture.quit()

    let text = String(decoding: try #require(suite.defaults.data(forKey: "session")), as: UTF8.self)
    #expect(!text.contains("Private"))
    #expect(!text.contains("\"title\":"))
    #expect(text.contains("titleHash"))
  }
}
