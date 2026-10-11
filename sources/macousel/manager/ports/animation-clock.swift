protocol AnimationClock: AnyObject {
  var onFrame: ((_ deltaTime: Double) -> Void)? { get set }
  var isRunning: Bool { get }
  func start()
  func stop()
}
