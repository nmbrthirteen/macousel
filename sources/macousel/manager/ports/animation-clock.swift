protocol AnimationClock: AnyObject {
  var frameInterval: Double { get }
  var now: ContinuousClock.Instant { get }
  var onFrame: ((_ deltaTime: Double) -> Void)? { get set }
  var isRunning: Bool { get }
  func start()
  func stop()
}
