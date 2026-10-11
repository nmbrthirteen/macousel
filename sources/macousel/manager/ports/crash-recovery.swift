protocol CrashRecovery: AnyObject {
  var isRecoveringFromCrash: Bool { get }
  func arm()
  func disarm()
}
