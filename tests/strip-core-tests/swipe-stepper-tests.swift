import Testing

@testable import StripCore

struct SwipeStepperTests {
  @Test func aTwitchBelowTheFirstThresholdStepsNowhere() {
    var stepper = SwipeStepper()

    #expect(stepper.advance(by: 0.03) == 0)
    #expect(stepper.advance(by: 0.02) == 0)
  }

  @Test func theFirstStepComesEarly() {
    var stepper = SwipeStepper()

    #expect(stepper.advance(by: 0.04) == 0)
    #expect(stepper.advance(by: 0.03) == 1)
  }

  @Test func aSecondStepNeedsALongerTravel() {
    var stepper = SwipeStepper()

    #expect(stepper.advance(by: 0.07) == 1)
    #expect(stepper.advance(by: 0.2) == 0)
    #expect(stepper.advance(by: 0.05) == 1)
  }

  @Test func oneLargeSampleCanCarrySeveralSteps() {
    var stepper = SwipeStepper()

    #expect(stepper.advance(by: -0.6) == -3)
  }

  @Test func theOtherDirectionStepsTheOtherWay() {
    var stepper = SwipeStepper()

    #expect(stepper.advance(by: -0.07) == -1)
  }

  @Test func jitterAroundAThresholdNeverStepsBack() {
    var stepper = SwipeStepper()

    #expect(stepper.advance(by: 0.07) == 1)
    #expect(stepper.advance(by: -0.03) == 0)
    #expect(stepper.advance(by: 0.03) == 0)
  }

  @Test func turningBackFarEnoughUndoesTheStep() {
    var stepper = SwipeStepper()

    #expect(stepper.advance(by: 0.07) == 1)
    #expect(stepper.advance(by: -0.26) == -1)
  }
}
