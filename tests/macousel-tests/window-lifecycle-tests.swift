import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct WindowLifecycleTests {
  private func launchedFixture(windows count: CGWindowID) throws -> (ControllerFixture, [FakeWindow])
  {
    let fixture = try ControllerFixture { $0.layout.defaultWidth = 0.25 }
    let windows = (1...count).map { fixture.open($0, atX: CGFloat($0) * 200) }
    fixture.source.focus(windows[0])
    fixture.launch()
    return (fixture, windows)
  }

  @Test func newWindowOpensBesideTheFocusedColumnAndTakesFocus() async throws {
    let (fixture, existing) = try launchedFixture(windows: 2)
    let newcomer = fixture.open(3, atX: 900, activating: true)

    var expected = ExpectedStrip(columns: [1, 3, 2], fraction: 0.25)
    expected.focus(3)
    #expect(await fixture.becomes { newcomer.frame == expected.frame(of: 3) })
    #expect(fixture.frames(of: existing + [newcomer]) == expected.frames)
    #expect(fixture.windowShowingFocusBorder(among: existing + [newcomer]) === newcomer)
  }

  @Test func newWindowFromABackgroundAppKeepsFocusAndScroll() async throws {
    let fixture = try ControllerFixture()
    let windows = (1...3).map { fixture.open($0, atX: CGFloat($0) * 200) }
    fixture.source.focus(windows[2])
    fixture.launch()
    let before = fixture.frames(of: windows)

    let background = fixture.open(4, app: .browser, atX: 100)

    var expected = ExpectedStrip(columns: [1, 2, 3, 4])
    expected.focus(3)
    #expect(await fixture.becomes { background.frame == expected.frame(of: 4) })
    #expect(fixture.frames(of: windows) == before)
    #expect(fixture.frames(of: windows + [background]) == expected.frames)
    #expect(fixture.windowShowingFocusBorder(among: windows + [background]) === windows[2])
  }

  @Test func closingTheFocusedWindowFocusesItsRightNeighbour() async throws {
    let (fixture, windows) = try launchedFixture(windows: 3)
    fixture.source.focus(windows[1])

    fixture.source.close(windows[1])

    let expected = ExpectedStrip(columns: [1, 3], fraction: 0.25)
    #expect(
      await fixture.becomes { fixture.frames(of: [windows[0], windows[2]]) == expected.frames })
    #expect(
      fixture.windowShowingFocusBorder(among: [windows[0], windows[2]]) === windows[2])
  }

  @Test func closingTheLastWindowFocusesItsLeftNeighbour() async throws {
    let (fixture, windows) = try launchedFixture(windows: 3)
    fixture.source.focus(windows[2])

    fixture.source.close(windows[2])

    let expected = ExpectedStrip(columns: [1, 2], fraction: 0.25)
    #expect(
      await fixture.becomes {
        fixture.windowShowingFocusBorder(among: [windows[0], windows[1]]) === windows[1]
      })
    #expect(fixture.frames(of: [windows[0], windows[1]]) == expected.frames)
  }

  @Test func minimizedWindowLeavesTheStripAndReturnsBesideTheFocusedColumn() async throws {
    let (fixture, windows) = try launchedFixture(windows: 3)
    fixture.source.focus(windows[2])

    fixture.source.minimize(windows[1])

    let withoutMinimized = ExpectedStrip(columns: [1, 3], fraction: 0.25)
    #expect(
      await fixture.becomes {
        fixture.frames(of: [windows[0], windows[2]]) == withoutMinimized.frames
      })

    fixture.source.focus(windows[2])
    fixture.source.restore(windows[1])

    let returned = ExpectedStrip(columns: [1, 3, 2], fraction: 0.25)
    #expect(await fixture.becomes { fixture.frames(of: windows) == returned.frames })
  }

  @Test func windowThatBecomesFullScreenLeavesTheStrip() async throws {
    let (fixture, windows) = try launchedFixture(windows: 3)

    windows[1].isFullScreen = true
    fixture.source.minimize(windows[1])
    fixture.source.restore(windows[1])

    let expected = ExpectedStrip(columns: [1, 3], fraction: 0.25)
    #expect(
      await fixture.becomes {
        fixture.frames(of: [windows[0], windows[2]]) == expected.frames
      })
  }

  @Test func windowDestroyedBeforeTheNextSynchronizationIsNeverTiled() async throws {
    let (fixture, windows) = try launchedFixture(windows: 2)
    let transient = fixture.open(3, atX: 900, activating: true)
    fixture.source.close(transient)

    let marker = fixture.open(4, atX: 950, activating: true)

    let expected = ExpectedStrip(columns: [1, 4, 2], fraction: 0.25)
    #expect(await fixture.becomes { marker.frame == expected.frame(of: 4) })
    #expect(transient.framesSet.isEmpty)
    #expect(fixture.frames(of: windows) == expected.frames.filter { $0.key != 4 })
  }
}
