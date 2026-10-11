import Testing

@testable import StripCore

struct SubmissionCadenceTests {
  private let interval = 1.0 / 120

  private func divisor(_ cadence: inout SubmissionCadence, ratio: Double) -> Int {
    cadence.update(frameInterval: interval, slowestAverage: ratio * interval)
  }

  @Test func startsAtEveryTick() {
    #expect(SubmissionCadence().divisor == 1)
  }

  @Test func staysAtEveryTickWhileApplyTimeIsLow() {
    var cadence = SubmissionCadence()
    #expect(divisor(&cadence, ratio: 0.1) == 1)
    #expect(divisor(&cadence, ratio: 0.6) == 1)
  }

  @Test func halvesAboveSixtyPercentOfAnInterval() {
    var cadence = SubmissionCadence()
    #expect(divisor(&cadence, ratio: 0.61) == 2)
    #expect(divisor(&cadence, ratio: 1.2) == 2)
  }

  @Test func quartersAboveOneAndAFifthIntervals() {
    var cadence = SubmissionCadence()
    #expect(divisor(&cadence, ratio: 1.21) == 4)
  }

  @Test func holdsTheThinnedCadenceUntilApplyTimeFallsUnderHalfAnInterval() {
    var cadence = SubmissionCadence()
    _ = divisor(&cadence, ratio: 0.9)
    #expect(divisor(&cadence, ratio: 0.55) == 2)
    #expect(divisor(&cadence, ratio: 0.5) == 2)
    #expect(divisor(&cadence, ratio: 0.49) == 1)
  }

  @Test func stepsDownFromQuarterToHalfWhenLoadEases() {
    var cadence = SubmissionCadence()
    _ = divisor(&cadence, ratio: 2)
    #expect(divisor(&cadence, ratio: 0.8) == 2)
  }

  @Test func ignoresANonPositiveFrameInterval() {
    var cadence = SubmissionCadence()
    #expect(cadence.update(frameInterval: 0, slowestAverage: 1) == 1)
  }
}
