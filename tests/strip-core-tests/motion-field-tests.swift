import CoreGraphics
import Testing

@testable import StripCore

struct MotionFieldTests {
  let config = LayoutConfig()
  let frameDuration = 1.0 / 120

  private func layout(_ strip: Strip) -> StripLayout {
    strip.layout(in: testViewport, config: config)
  }

  private func settle(_ field: inout MotionField, maximumFrames: Int = 600) -> Int {
    var frames = 0
    while !field.isSettled && frames < maximumFrames {
      field.advance(by: frameDuration)
      frames += 1
    }
    return frames
  }

  @Test func newWindowsStartAtTheirTarget() {
    var field = MotionField()
    let target = layout(makeStrip(3))
    field.retarget(to: target)
    #expect(field.isSettled)
    #expect(field.animated(target, in: testViewport) == target)
  }

  @Test func swappingColumnsAnimatesBothWindowsToTheirNewPlaces() throws {
    var strip = makeStrip(2)
    var field = MotionField()
    field.retarget(to: layout(strip))
    let startX = try #require(layout(strip)[id(2)]?.frame.minX)

    strip.moveFocused(.left)
    let target = layout(strip)
    field.retarget(to: target)
    #expect(!field.isSettled)
    #expect(field.animated(target, in: testViewport)[id(2)]?.frame.minX == startX)

    field.advance(by: frameDuration)
    let midX = try #require(field.animated(target, in: testViewport)[id(2)]?.frame.minX)
    let endX = try #require(target[id(2)]?.frame.minX)
    #expect(midX < startX && midX > endX)

    let frames = settle(&field)
    #expect(frames < 120)
    field.snap()
    #expect(field.animated(target, in: testViewport) == target)
  }

  @Test func motionNeverOvershootsFromRest() throws {
    var strip = makeStrip(2)
    var field = MotionField()
    field.retarget(to: layout(strip))
    strip.moveFocused(.left)
    let target = layout(strip)
    field.retarget(to: target)
    let endX = try #require(target[id(2)]?.frame.minX)
    for _ in 0..<240 {
      field.advance(by: frameDuration)
      let x = try #require(field.animated(target, in: testViewport)[id(2)]?.frame.minX)
      #expect(x >= endX)
    }
  }

  @Test func launchStartsMotionImmediatelyWithoutCoveringMostOfTheDistance() throws {
    var strip = makeStrip(2)
    var field = MotionField()
    field.retarget(to: layout(strip))
    let startX = try #require(layout(strip)[id(2)]?.frame.minX)
    strip.moveFocused(.left)
    let target = layout(strip)
    field.retarget(to: target)
    let endX = try #require(target[id(2)]?.frame.minX)
    field.advance(by: frameDuration)
    let x = try #require(field.animated(target, in: testViewport)[id(2)]?.frame.minX)
    let covered = (startX - x) / (startX - endX)
    #expect(covered > 0.03 && covered < 0.12)
  }

  @Test func enteringWindowsSlideInFromWhereTheyAre() throws {
    var strip = makeStrip(2)
    var field = MotionField()
    field.retarget(to: layout(strip))
    strip.insert(id(3), config: config)
    let target = layout(strip)
    let origin = CGPoint(x: 40, y: 300)
    field.retarget(to: target, entering: [id(3): origin])
    #expect(field.animated(target, in: testViewport)[id(3)]?.frame.origin == origin)
    #expect(!field.isSettled)
    _ = settle(&field)
    field.snap()
    #expect(field.animated(target, in: testViewport) == target)
    #expect(field.isTracking(id(3)))
  }

  @Test func snappingSkipsTheAnimation() {
    var strip = makeStrip(2)
    var field = MotionField()
    field.retarget(to: layout(strip))
    strip.moveFocused(.left)
    field.retarget(to: layout(strip), snapping: true)
    #expect(field.isSettled)
  }

  @Test func impartedVelocityMovesASettledField() throws {
    var field = MotionField()
    let target = layout(makeStrip(2))
    field.retarget(to: target)
    field.impart(horizontalVelocity: 900)
    #expect(!field.isSettled)
    field.advance(by: frameDuration)
    let x = try #require(field.animated(target, in: testViewport)[id(1)]?.frame.minX)
    let restX = try #require(target[id(1)]?.frame.minX)
    #expect(x > restX)
    _ = settle(&field)
    #expect(field.isSettled)
  }

  @Test func removedWindowsAreForgotten() {
    var strip = makeStrip(3)
    var field = MotionField()
    field.retarget(to: layout(strip))
    strip.remove(id(2))
    field.retarget(to: layout(strip), snapping: true)
    strip.insert(id(2), config: config)
    let target = layout(strip)
    field.retarget(to: target)
    #expect(field.animated(target, in: testViewport)[id(2)] == target[id(2)])
  }

  @Test func animatedPlacementsReclassifyVisibility() throws {
    var strip = makeStrip(4)
    strip.focusFirst()
    strip.scrollToFocus(viewportWidth: testViewport.width, config: config)
    var field = MotionField()
    field.retarget(to: layout(strip))
    strip.focusLast()
    strip.scrollToFocus(viewportWidth: testViewport.width, config: config)
    let target = layout(strip)
    field.retarget(to: target)
    let animated = try #require(field.animated(target, in: testViewport)[id(1)])
    #expect(animated.visibility == .full)
    #expect(target[id(1)]?.visibility == .offscreen(.left))
  }

  @Test func changingTheResponseKeepsPositionsAndTargets() throws {
    var strip = makeStrip(2)
    var field = MotionField()
    field.retarget(to: layout(strip))
    strip.moveFocused(.left)
    let target = layout(strip)
    field.retarget(to: target)
    field.advance(by: frameDuration)
    let before = field.animated(target, in: testViewport)
    field.setResponse(0.18)
    #expect(field.animated(target, in: testViewport) == before)
    _ = settle(&field)
    field.snap()
    #expect(field.animated(target, in: testViewport) == target)
  }
}

struct RubberBandTests {
  @Test(arguments: [0.0, 250.0, 500.0])
  func offsetsInsideTheRangeAreUnchanged(offset: Double) {
    #expect(RubberBand.resisted(offset, within: 0...500, dimension: 1000) == offset)
  }

  @Test func overshootIsResistedOnBothSides() {
    let past = RubberBand.resisted(700, within: 0...500, dimension: 1000)
    #expect(past > 500 && past < 700)
    let before = RubberBand.resisted(-200, within: 0...500, dimension: 1000)
    #expect(before < 0 && before > -200)
  }

  @Test func resistanceGrowsButNeverExceedsTheDimension() {
    let near = RubberBand.resisted(600, within: 0...500, dimension: 1000)
    let far = RubberBand.resisted(100_000, within: 0...500, dimension: 1000)
    #expect(far > near)
    #expect(far < 1500)
  }

  @Test func resistanceIsContinuousAtTheBoundary() {
    let justPast = RubberBand.resisted(500.001, within: 0...500, dimension: 1000)
    #expect(abs(justPast - 500) < 0.01)
  }
}
