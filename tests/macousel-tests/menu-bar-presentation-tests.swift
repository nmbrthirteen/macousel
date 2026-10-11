import Foundation
import Testing

@testable import Macousel

@MainActor
struct MenuBarPresentationTests {
  private let position = StripPosition(columnCount: 7, focusedIndex: 2, windowsInFocusedColumn: 1)

  private func presentation(
    _ indicator: MenuBarIndicator, status: WindowManager.Status = .running,
    position: StripPosition? = nil
  ) -> MenuBarPresentation {
    MenuBarPresentation(status: status, position: position, indicator: indicator)
  }

  @Test func positionModeShowsPills() {
    let result = presentation(.position, position: position)
    #expect(result.content == .pills(position))
    #expect(result.accessibilityLabel == "Macousel, column 3 of 7")
  }

  @Test func pagesModeShowsThePages() {
    let result = presentation(.pages, position: position)
    #expect(result.content == .pages(position))
    #expect(result.accessibilityLabel == "Macousel, column 3 of 7")
  }

  @Test func countModeShowsTheSymbolAndTheColumnNumber() {
    let result = presentation(.count, position: position)
    #expect(result.content == .symbolWithCount(symbol: "rectangle.split.3x1", text: "3/7"))
  }

  @Test func iconModeShowsOnlyTheSymbolButStillDescribesThePosition() {
    let result = presentation(.icon, position: position)
    #expect(result.content == .symbol("rectangle.split.3x1"))
    #expect(result.accessibilityLabel == "Macousel, column 3 of 7")
  }

  @Test func pastTwelveColumnsPositionFallsBackToTheCount() {
    let long = StripPosition(columnCount: 13, focusedIndex: 4, windowsInFocusedColumn: 1)
    let result = presentation(.position, position: long)
    #expect(result.content == .symbolWithCount(symbol: "rectangle.split.3x1", text: "5/13"))
  }

  @Test func anInvalidFocusedIndexInPagesModeFallsBackToTheCount() {
    let broken = StripPosition(columnCount: 3, focusedIndex: 5, windowsInFocusedColumn: 1)
    let result = presentation(.pages, position: broken)
    #expect(result.content == .symbolWithCount(symbol: "rectangle.split.3x1", text: "6/3"))
  }

  @Test(arguments: MenuBarIndicator.allCases)
  func withoutAPositionTheSymbolShows(indicator: MenuBarIndicator) {
    let result = presentation(indicator)
    #expect(result.content == .symbol("rectangle.split.3x1"))
    #expect(result.accessibilityLabel == "Macousel")
  }

  @Test(arguments: MenuBarIndicator.allCases)
  func pausedShowsThePauseSymbol(indicator: MenuBarIndicator) {
    let result = presentation(indicator, status: .paused, position: position)
    #expect(result.content == .symbol("pause.rectangle"))
    #expect(result.accessibilityLabel == "Macousel, paused")
  }

  @Test func missingPermissionShowsTheSymbolAndSaysWhy() {
    let result = presentation(.position, status: .needsPermission, position: position)
    #expect(result.content == .symbol("rectangle.split.3x1"))
    #expect(result.accessibilityLabel == "Macousel, needs Accessibility access")
  }

  @Test func theIndicatorDefaultsToPosition() {
    #expect(Preferences().menuBarIndicator == .position)
  }

  @Test func missingOrUnknownSettingsDecodeAsPosition() throws {
    let decoder = JSONDecoder()
    #expect(try decoder.decode(Preferences.self, from: Data("{}".utf8)).menuBarIndicator == .position)
    let unknown = Data(#"{"menuBarIndicator": "banner"}"#.utf8)
    #expect(try decoder.decode(Preferences.self, from: unknown).menuBarIndicator == .position)
  }

  @Test func theSettingRoundTrips() throws {
    var preferences = Preferences()
    preferences.menuBarIndicator = .count
    let data = try JSONEncoder().encode(preferences)
    #expect(try JSONDecoder().decode(Preferences.self, from: data).menuBarIndicator == .count)
  }

  @Test func titlesNameEachOptionInPickerOrder() {
    #expect(
      MenuBarIndicator.allCases.map(\.title)
        == ["Icon only", "Position on the strip", "Pages", "Column number"])
  }

  @Test func savedRawValuesStayStable() {
    #expect(MenuBarIndicator.allCases.map(\.rawValue) == ["icon", "position", "pages", "count"])
  }

  @Test func thePagesSettingRoundTrips() throws {
    var preferences = Preferences()
    preferences.menuBarIndicator = .pages
    let data = try JSONEncoder().encode(preferences)
    #expect(try JSONDecoder().decode(Preferences.self, from: data).menuBarIndicator == .pages)
  }
}
