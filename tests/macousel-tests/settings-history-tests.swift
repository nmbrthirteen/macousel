import Testing

@testable import Macousel

@MainActor
struct SettingsHistoryTests {
  @Test func startsWithNowhereToGo() {
    let history = SettingsHistory(current: .general)
    #expect(history.current == .general)
    #expect(!history.canGoBack)
    #expect(!history.canGoForward)
  }

  @Test func backAndForwardRetraceVisits() {
    var history = SettingsHistory(current: .general)
    history.visit(.layout)
    history.visit(.motion)

    history.goBack()
    #expect(history.current == .layout)
    history.goBack()
    #expect(history.current == .general)
    #expect(!history.canGoBack)

    history.goForward()
    history.goForward()
    #expect(history.current == .motion)
    #expect(!history.canGoForward)
  }

  @Test func visitingTheCurrentPaneRecordsNothing() {
    var history = SettingsHistory(current: .general)
    history.visit(.general)
    #expect(!history.canGoBack)
  }

  @Test func visitingAfterGoingBackDropsTheForwardPanes() {
    var history = SettingsHistory(current: .general)
    history.visit(.layout)
    history.goBack()
    history.visit(.pointer)
    #expect(!history.canGoForward)
    history.goBack()
    #expect(history.current == .general)
  }

  @Test func everyPaneSitsInExactlyOneGroup() {
    let listed = SettingsSectionGroup.allCases.flatMap { $0.sections(matching: "") }
    #expect(listed.count == SettingsSection.allCases.count)
    #expect(Set(listed) == Set(SettingsSection.allCases))

    let searched = SettingsSectionGroup.allCases.flatMap { $0.sections(matching: "gap") }
    #expect(searched.contains(.layout))
  }
}
