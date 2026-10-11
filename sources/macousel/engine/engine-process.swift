protocol EngineProcess: AnyObject {
  var exits: AsyncStream<Int32> { get }
  var isRunning: Bool { get }
  func terminate()
  func kill()
}

protocol EngineProcessLauncher: AnyObject {
  func launch(_ launch: EngineLaunch) throws -> any EngineProcess
}
