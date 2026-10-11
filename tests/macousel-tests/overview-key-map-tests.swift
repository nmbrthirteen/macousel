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

  @Test func shiftWithADirectionKeyMovesTheWindow() {
    let expectations: [(Int, Direction)] = [
      (kVK_LeftArrow, .left), (kVK_ANSI_H, .left), (kVK_RightArrow, .right), (kVK_ANSI_L, .right),
      (kVK_UpArrow, .up), (kVK_ANSI_K, .up), (kVK_DownArrow, .down), (kVK_ANSI_J, .down),
    ]
    for (code, direction) in expectations {
      #expect(OverviewKeyMap.key(forKeyCode: UInt16(code), shifted: true) == .moveWindow(direction))
    }
  }

  @Test func shiftWithADigitMovesTheWindowToThatPlace() {
    let digits = [
      kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7,
      kVK_ANSI_8, kVK_ANSI_9,
    ]
    for (index, code) in digits.enumerated() {
      #expect(
        OverviewKeyMap.key(forKeyCode: UInt16(code), shifted: true)
          == .moveWindowToPlace(index + 1))
      #expect(OverviewKeyMap.key(forKeyCode: UInt16(code)) == .jump(index + 1))
    }
  }

  @Test func equalsAndPlusWidenWhileMinusNarrows() {
    #expect(OverviewKeyMap.key(forKeyCode: UInt16(kVK_ANSI_Equal)) == .widen)
    #expect(OverviewKeyMap.key(forKeyCode: UInt16(kVK_ANSI_Equal), shifted: true) == .widen)
    #expect(OverviewKeyMap.key(forKeyCode: UInt16(kVK_ANSI_KeypadPlus)) == .widen)
    #expect(OverviewKeyMap.key(forKeyCode: UInt16(kVK_ANSI_Minus)) == .narrow)
    #expect(OverviewKeyMap.key(forKeyCode: UInt16(kVK_ANSI_KeypadMinus)) == .narrow)
  }

  @Test func shiftDoesNotChangeConfirmOrDismiss() {
    #expect(OverviewKeyMap.key(forKeyCode: UInt16(kVK_Return), shifted: true) == .confirm)
    #expect(OverviewKeyMap.key(forKeyCode: UInt16(kVK_Escape), shifted: true) == .dismiss)
  }
}
