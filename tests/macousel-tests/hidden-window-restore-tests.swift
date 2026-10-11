import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct HiddenWindowRestoreTests {
  private func sixWindows(_ fixture: ControllerFixture) -> (
    hidden: [FakeWindow], shown: [FakeWindow]
  ) {
    let hidden = (1...3).map { fixture.open($0, app: .editor, atX: CGFloat($0) * 100) }
    let shown = (4...6).map {
      fixture.open($0, app: .browser, atX: CGFloat($0) * 100, activating: $0 == 4)
    }
    return (hidden, shown)
  }

  @Test func quittingRestoresTheWindowsOfAnAppHiddenWithCommandH() async throws {
    let fixture = try ControllerFixture()
    let (hidden, shown) = sixWindows(fixture)
    let originals = fixture.frames(of: hidden + shown)
    fixture.launch()

    fixture.source.hideApp(.editor)

    let remaining = ExpectedStrip(columns: [4, 5, 6])
    #expect(await fixture.becomes { fixture.frames(of: shown) == remaining.frames })
    fixture.quit()

    #expect(fixture.frames(of: hidden + shown) == originals)
  }

  @Test func pausingRestoresTheWindowsOfAnAppHiddenWithCommandH() async throws {
    let fixture = try ControllerFixture()
    let (hidden, shown) = sixWindows(fixture)
    let originals = fixture.frames(of: hidden + shown)
    fixture.launch()
    fixture.source.hideApp(.editor)
    let remaining = ExpectedStrip(columns: [4, 5, 6])
    #expect(await fixture.becomes { fixture.frames(of: shown) == remaining.frames })

    fixture.manager.perform(.togglePaused)

    #expect(fixture.frames(of: hidden + shown) == originals)
  }
}
