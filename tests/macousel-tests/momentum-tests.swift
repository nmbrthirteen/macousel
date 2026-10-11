import CoreGraphics
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct MomentumTests {
  private func launchedRow() throws -> (ControllerFixture, [FakeWindow]) {
    let fixture = try ControllerFixture()
    let row = fixture.openRow(6)
    fixture.launch()
    return (fixture, row)
  }

  private func drag(
    _ fixture: ControllerFixture, steps: Int, spacing: Duration, delta: Double = -40
  ) {
    fixture.gestures.onScroll?(delta, .began)
    for _ in 0..<steps {
      fixture.clock.advance(by: spacing)
      fixture.gestures.onScroll?(delta, .changed)
    }
  }

  @Test func fastFlickAdvancesAtLeastOneColumn() throws {
    let (fixture, row) = try launchedRow()

    drag(fixture, steps: 5, spacing: .milliseconds(10))
    fixture.clock.advance(by: .milliseconds(10))
    fixture.gestures.onScroll?(0, .ended)

    #expect(row[1].focusCount + row[2].focusCount == 1)
    #expect(row[0].focusCount == 0)
  }

  @Test func slowReleaseRestsOnTheNearestColumn() throws {
    let (fixture, row) = try launchedRow()
    let initial = fixture.frames(of: row)

    drag(fixture, steps: 3, spacing: .milliseconds(90), delta: -10)
    fixture.clock.advance(by: .milliseconds(50))
    fixture.gestures.onScroll?(0, .ended)

    #expect(fixture.frames(of: row) == initial)
    #expect(row.allSatisfy { $0.focusCount == 0 })
  }

  @Test func pauseBeforeReleaseCarriesNoMomentum() throws {
    let (fixture, row) = try launchedRow()
    let initial = fixture.frames(of: row)

    drag(fixture, steps: 5, spacing: .milliseconds(10), delta: -15)
    fixture.clock.advance(by: .milliseconds(150))
    fixture.gestures.onScroll?(0, .ended)

    #expect(fixture.frames(of: row) == initial)
    #expect(row.allSatisfy { $0.focusCount == 0 })
  }
}
