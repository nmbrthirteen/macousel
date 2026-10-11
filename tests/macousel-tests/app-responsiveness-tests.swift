import Testing
import WindowSystem

struct AppResponsivenessTests {
  private func recorded(_ milliseconds: [Double]) -> AppResponsiveness {
    var app = AppResponsiveness()
    for value in milliseconds { app.record(milliseconds: value) }
    return app
  }

  private func slowApp() -> AppResponsiveness {
    recorded([AppResponsiveness.slowSingleSetMilliseconds])
  }

  @Test func aNewAppStartsResponsive() {
    #expect(!AppResponsiveness().isSlow)
  }

  @Test func aSingleSetOfTheStallThresholdMakesTheAppSlow() {
    #expect(recorded([2, 2, AppResponsiveness.slowSingleSetMilliseconds]).isSlow)
  }

  @Test func aSingleSetJustBelowTheStallThresholdDoesNot() {
    #expect(!recorded([2, 99.9]).isSlow)
  }

  @Test func aMedianAboveTheLimitOverTheLastEightSetsMakesTheAppSlow() {
    #expect(recorded(Array(repeating: 7, count: AppResponsiveness.recentSetCount)).isSlow)
  }

  @Test func aMedianAtTheLimitDoesNot() {
    #expect(!recorded(Array(repeating: 6, count: AppResponsiveness.recentSetCount)).isSlow)
  }

  @Test func oneOutlierBelowTheStallThresholdDoesNotMakeTheAppSlow() {
    let sets = Array(repeating: 1.0, count: 7) + [99]
    #expect(!recorded(sets).isSlow)
  }

  @Test func fewerThanEightSlowishSetsAreNotEnoughForTheMedianRule() {
    #expect(!recorded(Array(repeating: 20, count: AppResponsiveness.recentSetCount - 1)).isSlow)
  }

  @Test func onlyTheLastEightSetsCountTowardTheMedian() {
    let early = Array(repeating: 20.0, count: 3)
    let recent = Array(repeating: 1.0, count: AppResponsiveness.recentSetCount)
    #expect(!recorded(early + recent).isSlow)
  }

  @Test func fiveQuickSetsInARowRecoverASlowApp() {
    var app = slowApp()
    for _ in 0..<AppResponsiveness.recoveryStreakLength { app.record(milliseconds: 1) }
    #expect(!app.isSlow)
  }

  @Test func fourQuickSetsDoNot() {
    var app = slowApp()
    for _ in 0..<(AppResponsiveness.recoveryStreakLength - 1) { app.record(milliseconds: 1) }
    #expect(app.isSlow)
  }

  @Test func aSetAtTheRecoveryCeilingBreaksTheStreak() {
    var app = slowApp()
    for _ in 0..<(AppResponsiveness.recoveryStreakLength - 1) { app.record(milliseconds: 1) }
    app.record(milliseconds: AppResponsiveness.recoveryCeilingMilliseconds)
    app.record(milliseconds: 1)
    #expect(app.isSlow)
  }

  @Test func aRecoveredAppIsNotSlowAgainFromTheSetsThatMadeItSlow() {
    var app = recorded(Array(repeating: 7, count: AppResponsiveness.recentSetCount))
    for _ in 0..<AppResponsiveness.recoveryStreakLength { app.record(milliseconds: 1) }
    app.record(milliseconds: 1)
    #expect(!app.isSlow)
  }
}
