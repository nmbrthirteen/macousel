final class ReconcileQueue {
  var onRun: ((ReconcileRequest) -> Void)?
  private(set) var epoch = 0
  private var isRunning = false
  private var waiting: ReconcileRequest?

  func submit(_ request: ReconcileRequest) {
    guard !isRunning else {
      waiting = waiting.map { $0.merged(with: request) } ?? request
      return
    }
    isRunning = true
    onRun?(request)
  }

  func finish() {
    isRunning = false
    guard let next = waiting else { return }
    waiting = nil
    submit(next)
  }

  func cancel() {
    epoch += 1
    isRunning = false
    waiting = nil
  }
}
