import Testing

@testable import StripCore

struct SpringTests {
  @Test func startsSettledAtItsValue() {
    let spring = Spring(value: 10)
    #expect(spring.target == 10)
    #expect(spring.velocity == 0)
    #expect(spring.isSettled)
  }

  @Test(arguments: [0.1, 0.28, 0.6])
  func convergesToTarget(response: Double) {
    var spring = Spring(value: 0, response: response)
    spring.target = 500
    var elapsed = 0.0
    while !spring.isSettled && elapsed < 5 {
      spring.advance(by: 1.0 / 120.0)
      elapsed += 1.0 / 120.0
    }
    #expect(spring.isSettled)
    #expect(elapsed < response * 2)
    for _ in 0..<600 { spring.advance(by: 1.0 / 120.0) }
    #expect(abs(spring.value - 500) < 1e-6)
  }

  @Test(arguments: [500.0, -500.0])
  func neverOvershootsFromRest(distance: Double) {
    var spring = Spring(value: 0)
    spring.target = distance
    for _ in 0..<1000 {
      spring.advance(by: 1.0 / 240.0)
      #expect(abs(spring.value) <= abs(distance) + 1e-9)
      #expect(spring.value * distance >= 0)
    }
  }

  @Test func stepsComposeExactly() {
    var coarse = Spring(value: 0)
    coarse.target = 300
    var fine = coarse
    coarse.advance(by: 0.2)
    for _ in 0..<200 { fine.advance(by: 0.001) }
    #expect(abs(coarse.value - fine.value) < 1e-6)
    #expect(abs(coarse.velocity - fine.velocity) < 1e-4)
  }

  @Test(arguments: [10.0, 1e3, 1e9])
  func stableWithLargeTimeStep(dt: Double) {
    var spring = Spring(value: -100, response: 0.28)
    spring.velocity = 5000
    spring.target = 400
    spring.advance(by: dt)
    #expect(spring.value.isFinite)
    #expect(spring.velocity.isFinite)
    #expect(abs(spring.value - 400) < 1e-6)
    #expect(spring.isSettled)
  }

  @Test func nonPositiveTimeStepChangesNothing() {
    var spring = Spring(value: 0)
    spring.target = 100
    let before = spring
    spring.advance(by: 0)
    spring.advance(by: -1)
    #expect(spring == before)
  }

  @Test func isSettledThresholds() {
    var spring = Spring(value: 0)
    spring.target = 0.4
    #expect(spring.isSettled)
    spring.target = 0.5
    #expect(!spring.isSettled)
    spring.target = 0
    spring.velocity = 4.9
    #expect(spring.isSettled)
    spring.velocity = -5
    #expect(!spring.isSettled)
  }

  @Test func snapJumpsToTargetAndStops() {
    var spring = Spring(value: 0)
    spring.target = 100
    spring.advance(by: 0.05)
    spring.snap()
    #expect(spring.value == 100)
    #expect(spring.velocity == 0)
    #expect(spring.isSettled)
  }
}
