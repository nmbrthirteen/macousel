@testable import Macousel

@MainActor
final class FakeCrashRecovery: CrashRecovery {
  var isRecoveringFromCrash = false
  private(set) var isArmed = false
  private(set) var armCount = 0
  private(set) var disarmCount = 0

  func arm() {
    isArmed = true
    armCount += 1
  }

  func disarm() {
    isArmed = false
    disarmCount += 1
  }
}
