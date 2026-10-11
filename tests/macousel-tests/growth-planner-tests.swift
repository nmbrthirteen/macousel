import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct GrowthPlannerTests {
  private let planner = GrowthPlanner()
  private let viewport = CGRect(x: 0, y: 24, width: 1000, height: 776)

  private func placements() -> [Placement] {
    var strip = Strip()
    strip.append(WindowID(1), width: .fraction(0.5))
    strip.append(WindowID(2), width: .fraction(0.5))
    return strip.layout(in: viewport, config: LayoutConfig()).placements
  }

  private func plan(
    previousWidthOfFirst: CGFloat, firstIsParked: Bool = false
  ) -> [PlannedFrame] {
    placements().map { placement in
      let isFirst = placement.window == WindowID(1)
      var previous = placement.frame
      if isFirst { previous.size.width = previousWidthOfFirst }
      var target = placement.frame
      if isFirst { target.size.width += 200 }
      return PlannedFrame(
        window: placement.window.rawValue, placement: placement, target: target,
        previous: previous, isParked: isFirst && firstIsParked)
    }
  }

  @Test func aGrowerThatWouldCoverANeighbourIsHeldAtItsPreviousSize() throws {
    let planned = plan(previousWidthOfFirst: 300)

    let submissions = planner.submissions(for: planned, holdingGrowth: true)

    let first = try #require(submissions.first { $0.window == 1 })
    #expect(first.frame.width == 300)
    #expect(first.frame.origin == planned[0].target.origin)
  }

  @Test func settlingReleasesEveryHoldEvenWhileTheNeighbourStillOverlaps() throws {
    let planned = plan(previousWidthOfFirst: 300)

    let submissions = planner.submissions(for: planned, holdingGrowth: false)

    #expect(submissions.map(\.frame) == planned.map(\.target))
  }

  @Test func aParkedGrowerIsResizedAtOnce() throws {
    let planned = plan(previousWidthOfFirst: 300, firstIsParked: true)

    let submissions = planner.submissions(for: planned, holdingGrowth: true)

    let first = try #require(submissions.first { $0.window == 1 })
    #expect(first.frame == planned[0].target)
  }

  @Test func shrinkersAreSubmittedBeforeGrowers() {
    let planned = plan(previousWidthOfFirst: 300)

    let submissions = planner.submissions(for: planned, holdingGrowth: true)

    #expect(submissions.map(\.window) == [2, 1])
  }

  @Test func aWindowWithoutAPreviousSizeIsNeverHeld() throws {
    var planned = plan(previousWidthOfFirst: 300)
    planned[0].previous = nil

    let submissions = planner.submissions(for: planned, holdingGrowth: true)

    let first = try #require(submissions.first { $0.window == 1 })
    #expect(first.frame == planned[0].target)
  }
}
