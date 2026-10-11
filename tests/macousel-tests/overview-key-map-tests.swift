import Carbon.HIToolbox
import StripCore
import Testing

@testable import Macousel

@MainActor
struct OverviewKeyMapTests {
  @Test func arrowsAndVimLettersMove() {
    let expectations: [(Int, OverviewKey)] = [
      (kVK_LeftArrow, .move(.left)), (kVK_ANSI_H, .move(.left)),
      (kVK_RightArrow, .move(.right)), (kVK_ANSI_L, .move(.right)),
      (kVK_UpArrow, .move(.up)), (kVK_ANSI_K, .move(.up)),
      (kVK_DownArrow, .move(.down)), (kVK_ANSI_J, .move(.down)),
    ]
    for (code, key) in expectations {
      #expect(OverviewKeyMap.key(forKeyCode: UInt16(code)) == key)
    }
  }

  @Test func digitsJumpToTheirColumn() {
    let digits = [
      kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7,
      kVK_ANSI_8, kVK_ANSI_9,
    ]
    for (index, code) in digits.enumerated() {
      #expect(OverviewKeyMap.key(forKeyCode: UInt16(code)) == .jump(index + 1))
    }
  }

  @Test func returnConfirmsAndEscapeDismisses() {
    #expect(OverviewKeyMap.key(forKeyCode: UInt16(kVK_Return)) == .confirm)
    #expect(OverviewKeyMap.key(forKeyCode: UInt16(kVK_Escape)) == .dismiss)
  }

  @Test func otherKeysMapToNothing() {
    #expect(OverviewKeyMap.key(forKeyCode: UInt16(kVK_ANSI_Q)) == nil)
    #expect(OverviewKeyMap.key(forKeyCode: UInt16(kVK_ANSI_0)) == nil)
  }
}
