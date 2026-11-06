import Testing

@testable import Macousel

struct MenuTitleTests {
  @Test(arguments: [
    ("Focus left", "Focus Left"),
    ("Move up", "Move Up"),
    ("Stack with the column on the left", "Stack with the Column on the Left"),
    ("Pop out to the left", "Pop Out to the Left"),
    ("Send to next display, stay here", "Send to Next Display, Stay Here"),
    ("Focus column 9 (last)", "Focus Column 9 (Last)"),
    ("Show or hide overview", "Show or Hide Overview"),
    ("Jump to a column", "Jump to a Column"),
    ("Overview and tiling", "Overview and Tiling"),
  ])
  func capitalizesLikeAppleTitleStyle(sentence: String, title: String) {
    #expect(MenuTitle.titleCased(sentence) == title)
  }

  @Test func keepsTheFirstAndLastWordCapitalizedEvenWhenMinor() {
    #expect(MenuTitle.titleCased("a way in") == "A Way In")
  }
}
