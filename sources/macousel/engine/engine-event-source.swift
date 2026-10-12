protocol EngineEventSource: AnyObject {
  var onEvent: ((EngineEvent) -> Void)? { get set }
  var onConnect: (() -> Void)? { get set }
  func start()
  func stop()
}
