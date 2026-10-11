import CoreGraphics
import Testing

@testable import StripCore

struct ParkingPolicyTests {
  let config = LayoutConfig()
  let display = CGRect(x: 0, y: 0, width: 1016, height: 816)

  private func policy(left: Bool = false, right: Bool = false) -> ParkingPolicy {
    ParkingPolicy(displayBounds: display, hasLeftNeighbor: left, hasRightNeighbor: right)
  }

  private func placements(focusing focused: UInt32) -> StripLayout {
    var strip = makeStrip(5)
    strip.focus(id(focused))
    strip.scrollToFocus(viewportWidth: testViewport.width, config: config)
    return strip.layout(in: testViewport, config: config)
  }

  @Test func fullyVisibleWindowKeepsItsFrame() throws {
    let placement = try #require(placements(focusing: 1)[id(1)])
    #expect(policy().frame(for: placement, in: testViewport) == placement.frame)
    #expect(!policy().isParked(placement, in: testViewport))
  }

  @Test func offscreenWindowParksBeyondItsOwnEdgeWhenThatEdgeIsOpen() throws {
    let placement = try #require(placements(focusing: 1)[id(5)])
    let parked = policy().frame(for: placement, in: testViewport)
    #expect(parked.minX == display.maxX - ParkingPolicy.visibleSliver)
    #expect(parked.size == placement.frame.size)
    #expect(policy().isParked(placement, in: testViewport))
  }

  @Test func offscreenWindowParksOnTheOppositeEdgeWhenANeighborBlocksItsOwn() throws {
    let placement = try #require(placements(focusing: 1)[id(5)])
    let parked = policy(right: true).frame(for: placement, in: testViewport)
    #expect(parked.maxX == display.minX + ParkingPolicy.visibleSliver)
  }

  @Test func offscreenWindowParksBelowWhenBothEdgesHaveNeighbors() throws {
    let placement = try #require(placements(focusing: 1)[id(5)])
    let parked = policy(left: true, right: true).frame(for: placement, in: testViewport)
    #expect(parked.minY == display.maxY - ParkingPolicy.visibleSliver)
  }

  @Test func partialWindowStaysInPlaceOnAnOpenEdge() throws {
    let partial = try placement(of: 1, scrolledTo: 300)
    #expect(policy().frame(for: partial, in: testViewport) == partial.frame)
  }

  private func placement(of window: UInt32, scrolledTo offset: Double) throws -> Placement {
    var strip = makeStrip(3)
    strip.focus(id(2))
    let layout = strip.layout(in: testViewport, config: config, scrollOffset: offset)
    return try #require(layout[id(window)])
  }

  @Test func partialWindowOverhangingANeighborStaysWhileUnderHalfBeyondTheEdge() throws {
    let placement = try placement(of: 1, scrolledTo: 255)
    #expect(placement.visibility == .partial)
    #expect(policy(left: true).frame(for: placement, in: testViewport) == placement.frame)
    #expect(!policy(left: true).isParked(placement, in: testViewport))
  }

  @Test func partialWindowStaysWhenExactlyHalfIsBeyondTheEdge() throws {
    let placement = try placement(of: 1, scrolledTo: 256)
    #expect(!policy(left: true).isParked(placement, in: testViewport))
  }

  @Test func partialWindowParksOnceMoreThanHalfIsBeyondTheLeftEdge() throws {
    let placement = try placement(of: 1, scrolledTo: 257)
    #expect(placement.visibility == .partial)
    #expect(policy(left: true).isParked(placement, in: testViewport))
  }

  @Test func partialWindowStaysWhileUnderHalfBeyondTheRightEdge() throws {
    let placement = try placement(of: 3, scrolledTo: 249)
    #expect(placement.visibility == .partial)
    #expect(!policy(right: true).isParked(placement, in: testViewport))
  }

  @Test func partialWindowParksOnceMoreThanHalfIsBeyondTheRightEdge() throws {
    let placement = try placement(of: 3, scrolledTo: 247)
    #expect(placement.visibility == .partial)
    #expect(policy(right: true).isParked(placement, in: testViewport))
  }

  @Test func partialWindowIgnoresNeighborsOnTheOtherSide() throws {
    let placement = try placement(of: 1, scrolledTo: 300)
    #expect(!policy(right: true).isParked(placement, in: testViewport))
  }

  @Test func insertHonorsAnExplicitWidth() {
    var strip = makeStrip(1)
    strip.insert(id(9), width: .fraction(0.75), config: config)
    #expect(strip.columns[1].width == .fraction(0.75))
    #expect(strip.focusedWindow == id(9))
  }
}
