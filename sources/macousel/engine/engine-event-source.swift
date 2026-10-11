protocol EngineEventSource: AnyObject {
  var onEvent: ((EngineEvent) -> Void)? { get set }
  func start()
  func stop()
}
