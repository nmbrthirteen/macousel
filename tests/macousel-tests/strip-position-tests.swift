import CoreGraphics
import Observation
import StripCore
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct StripPositionTests {
  private func launched(windows: CGWindowID) throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(windows)
    fixture.launch()
    return (fixture, row)
  }

  @MainActor
  private final class PositionObserver {
    private(set) var changes = 0
    private let manager: WindowManager

    init(_ manager: WindowManager) {
      self.manager = manager
      observe()
    }

    private func observe() {
      withObservationTracking {
        _ = manager.position
      } onChange: {
        MainActor.assumeIsolated {
          self.changes += 1
          self.observe()
        }
      }
    }
  }

  @Test func thereIsNoPositionBeforeTilingStarts() throws {
    let fixture = try ControllerFixture()
    #expect(fixture.manager.position == nil)
  }

  @Test func thereIsNoPositionForAnEmptyStrip() throws {
    let fixture = try ControllerFixture()
    fixture.launch()
    #expect(fixture.manager.position == nil)
  }

  @Test func theLaunchedStripReportsItsColumnsAndFocus() throws {
    let (fixture, _) = try launched(windows: 4)
    #expect(fixture.manager.position?.columnCount == 4)
    #expect(fixture.manager.position?.windowsInFocusedColumn == 1)
  }

  @Test func theFocusedIndexFollowsFocusCommands() throws {
    let (fixture, _) = try launched(windows: 4)
    fixture.manager.perform(.focusLast)
    #expect(fixture.manager.position?.focusedIndex == 3)
    fixture.manager.perform(.focusLeft)
    fixture.manager.perform(.focusFirst)
    #expect(fixture.manager.position?.focusedIndex == 0)
    #expect(fixture.manager.position?.columnNumber == 1)
  }

  @Test func stackingChangesTheColumnCountAndTheFocusedColumnSize() throws {
    let (fixture, _) = try launched(windows: 3)
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    let position = try #require(fixture.manager.position)
    #expect(position.columnCount == 2)
    #expect(position.focusedIndex == 0)
    #expect(position.windowsInFocusedColumn == 2)
  }

  @Test func everyColumnReportsItsWidthShareAndRowCount() throws {
    let (fixture, _) = try launched(windows: 3)
    fixture.manager.perform(.focusRight)
    fixture.manager.perform(.stackLeft)
    let pages = try #require(fixture.manager.position).pages
    #expect(pages.map(\.rowCount) == [2, 1])
    #expect(pages.allSatisfy { $0.widthShare > 0 && $0.widthShare <= 1 })
  }

  @Test func resizingAColumnChangesItsWidthShare() throws {
    let (fixture, _) = try launched(windows: 3)
    let before = try #require(fixture.manager.position).pages[0].widthShare
    fixture.manager.perform(.cycleWidth)
    let after = try #require(fixture.manager.position).pages[0].widthShare
    #expect(after != before)
  }

  @Test func aNewWindowAddsAColumn() async throws {
    let (fixture, _) = try launched(windows: 2)
    fixture.open(3, atX: 600, activating: true)
    #expect(await fixture.becomes { fixture.manager.position?.columnCount == 3 })
  }

  @Test func aClosedWindowRemovesAColumn() async throws {
    let (fixture, row) = try launched(windows: 3)
    fixture.source.close(row[2])
    #expect(await fixture.becomes { fixture.manager.position?.columnCount == 2 })
  }

  @Test func closingTheLastWindowClearsThePosition() async throws {
    let (fixture, row) = try launched(windows: 1)
    fixture.source.close(row[0])
    #expect(await fixture.becomes { fixture.manager.position == nil })
  }

  @Test func pausingClearsThePositionAndResumingRestoresIt() async throws {
    let (fixture, _) = try launched(windows: 3)
    fixture.manager.perform(.togglePaused)
    #expect(fixture.manager.position == nil)
    fixture.manager.perform(.togglePaused)
    #expect(await fixture.becomes { fixture.manager.position?.columnCount == 3 })
  }

  @Test func theActiveDisplayFollowsThePointer() async throws {
    let pair = [Display.leftOfPair, Display.rightOfPair]
    let fixture = try ControllerFixture(displays: pair) {
      $0.layout.defaultWidth = 0.25
      $0.displayFollowsPointer = true
    }
    fixture.open(1, atX: 100, activating: true)
    fixture.open(2, atX: 400)
    fixture.open(3, atX: 1100)
    fixture.open(4, atX: 1400)
    fixture.open(5, atX: 1450)
    fixture.launch()
    let before = fixture.manager.position
    fixture.pointer.moveTo(CGPoint(x: 1500, y: 400))
    #expect(await fixture.becomes { fixture.manager.position != before })
    #expect(fixture.manager.position?.columnCount == 3)
  }

  @Test func anUnchangedLayoutDoesNotReassignThePosition() throws {
    let (fixture, _) = try launched(windows: 3)
    let observer = PositionObserver(fixture.manager)
    fixture.manager.perform(.focusFirst)
    fixture.manager.perform(.focusLeft)
    fixture.manager.perform(.focusFirst)
    #expect(observer.changes == 0)
    fixture.manager.perform(.cycleWidth)
    #expect(observer.changes == 1)
    fixture.manager.perform(.focusFirst)
    #expect(observer.changes == 1)
    fixture.manager.perform(.focusRight)
    #expect(observer.changes == 2)
  }
}
