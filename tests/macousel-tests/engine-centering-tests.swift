import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct EngineCenteringTests {
  private let fixture = EngineDragFixture()
  private let center = ["window", "center"]
  private let resting = CGPoint(x: 300, y: 200)
  private let gap = CGPoint(x: 1980, y: 100)
  private let far = CGSize(width: 300, height: 100)

  private func enable() {
    fixture.probe.centersFocus = true
    fixture.engineWarpsThePointerOnCenter()
    fixture.pointer.movePrimarySilently(to: resting)
  }

  @Test func nothingIsSentWhenCenteringIsOff() async {
    let centered = await fixture.centering.centerFocusedColumn()

    #expect(!centered)
    #expect(fixture.commands.sent.isEmpty)
  }

  @Test func centersTheStripAndPutsThePointerBack() async {
    enable()

    let centered = await fixture.centering.centerFocusedColumn()

    #expect(centered)
    #expect(fixture.commands.sent == [center])
    #expect(fixture.pointer.warps == [resting])
    #expect(fixture.pointer.location == resting)
  }

  @Test func waitsUntilNoWindowMoves() async {
    enable()
    let strip = fixture.strip
    let probe = fixture.probe
    var sleepsWhenSent: Int?
    strip.afterApply = { _, words in
      if words == ["window", "center"] { sleepsWhenSent = probe.centeringSleeps }
    }
    let layouts: [[[Int32]]] = [[[2], [1], [3]], [[2], [3], [1]], [[1, 2], [3]]]
    var remaining = layouts[...]
    let commands = fixture.commands
    let moving = EngineCentering(
      commands: commands, pointer: fixture.pointer, displays: { [.fake(width: 4000)] },
      isEnabled: { true },
      sleep: { _ in
        probe.centeringSleeps += 1
        if let next = remaining.popFirst() { strip.columns = next }
        strip.advance()
        await Task.yield()
      },
      now: { FrozenInstant.now })

    let centered = await moving.centerFocusedColumn()

    #expect(centered)
    #expect(sleepsWhenSent.map { $0 >= layouts.count + EngineCentering.restingPolls } == true)
  }

  @Test func leavesAPointerAlreadyAtTheCenterAlone() async {
    enable()
    fixture.pointer.movePrimarySilently(to: CGPoint(x: 2010, y: 395))

    let centered = await fixture.centering.centerFocusedColumn()

    #expect(centered)
    #expect(fixture.commands.sent == [center])
    #expect(fixture.pointer.warps.isEmpty)
  }

  @Test func followsAPointerThatKeepsMovingBeforeTheEngineWarpsIt() async {
    enable()
    fixture.strip.lag = 3
    let pointer = fixture.pointer
    let travelled = CGPoint(x: 340, y: 260)
    let strip = fixture.strip
    var nudged = false
    strip.afterApply = { _, words in
      guard words == ["window", "center"] else { return }
      pointer.movePrimarySilently(to: EngineDragFixture.displayCenter)
    }
    fixture.probe.onSleep = nil
    let commands = fixture.commands
    let centering = EngineCentering(
      commands: commands, pointer: pointer, displays: { [.fake(width: 4000)] },
      isEnabled: { true },
      sleep: { _ in
        if commands.sent.contains(["window", "center"]), !nudged {
          nudged = true
          pointer.movePrimarySilently(to: travelled)
        } else {
          strip.advance()
        }
        await Task.yield()
      },
      now: { FrozenInstant.now })

    _ = await centering.centerFocusedColumn()

    #expect(pointer.warps == [travelled])
  }

  @Test func givesUpQuietlyWhenTheEngineNeverWarps() async {
    fixture.probe.centersFocus = true
    fixture.pointer.movePrimarySilently(to: resting)

    let centered = await fixture.centering.centerFocusedColumn()

    #expect(centered)
    #expect(fixture.pointer.warps.isEmpty)
  }

  @Test func doesNothingWithoutAFocusedTiledWindow() async {
    enable()
    fixture.strip.focused = nil

    let centered = await fixture.centering.centerFocusedColumn()

    #expect(!centered)
    #expect(fixture.commands.sent.isEmpty)
  }

  @Test func aDropCentersTheStripAfterTheMove() async {
    enable()
    await fixture.start()
    fixture.press()
    fixture.drag(by: far, to: gap)

    fixture.pointer.releasePrimary()

    #expect(await fixture.eventually { !fixture.drag.isSettling })
    #expect(fixture.strip.columns == [[2], [1], [3]])
    #expect(fixture.commands.sent.last == center)
    #expect(fixture.commands.sent.filter { $0 == center }.count == 1)
    #expect(fixture.pointer.location == gap)
  }

  @Test func aDropBackOnTheOwnSlotStillCentersTheStrip() async {
    enable()
    await fixture.start()
    fixture.press()
    fixture.drag(by: far, to: gap)
    fixture.drag(by: far, to: CGPoint(x: 480, y: 100))

    fixture.pointer.releasePrimary()

    #expect(await fixture.eventually { !fixture.drag.isSettling })
    #expect(fixture.commands.sent == [center])
  }

  @Test func aCancelledDragStillCentersTheStrip() async {
    enable()
    await fixture.start()
    fixture.press()
    fixture.drag(by: far, to: gap)
    fixture.pointer.pressEscape()

    fixture.pointer.releasePrimary()

    #expect(await fixture.eventually { !fixture.drag.isSettling })
    #expect(fixture.commands.sent == [center])
  }

  @Test func aLongDragCentersInsteadOfSnapping() async {
    enable()
    await fixture.start()
    fixture.press()
    fixture.drag(by: far, to: gap)
    fixture.drag(by: far, to: CGPoint(x: 480, y: 100))
    fixture.clock.advance(by: .seconds(5))

    fixture.pointer.releasePrimary()

    #expect(await fixture.eventually { !fixture.drag.isSettling })
    #expect(fixture.commands.sent == [center])
  }

  @Test func aPlainClickSendsNothing() async {
    enable()
    await fixture.start()
    fixture.press()

    fixture.pointer.releasePrimary()
    for _ in 0..<50 { await Task.yield() }

    #expect(fixture.commands.sent.isEmpty)
    #expect(!fixture.drag.isSettling)
  }
}
