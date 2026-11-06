import Testing

@testable import Macousel

@MainActor
struct FocusHistoryTests {
  @Test func startsWithNoPreviousWindow() {
    var history = FocusHistory()
    history.note(1)

    #expect(history.current == 1)
    #expect(history.previous == nil)
  }

  @Test func remembersTheWindowFocusedBeforeTheCurrentOne() {
    var history = FocusHistory()
    history.note(1)
    history.note(2)
    history.note(3)

    #expect(history.current == 3)
    #expect(history.previous == 2)
  }

  @Test func theSameWindowAgainKeepsThePreviousOne() {
    var history = FocusHistory()
    history.note(1)
    history.note(2)
    history.note(2)

    #expect(history.previous == 1)
  }

  @Test func goingBackSwapsTheTwoWindows() {
    var history = FocusHistory()
    history.note(1)
    history.note(2)
    history.note(1)

    #expect(history.current == 1)
    #expect(history.previous == 2)
  }
}
