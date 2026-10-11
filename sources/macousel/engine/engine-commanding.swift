protocol EngineCommanding: AnyObject {
  func send(_ words: [String]) async
  func fetchSnapshot() async -> EngineSnapshot?
  func isAnswering() async -> Bool
}
