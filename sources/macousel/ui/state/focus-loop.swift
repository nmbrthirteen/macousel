import Observation

@Observable
final class FocusLoop {
  let restingColumn: Int
  let alternateColumn: Int
  let interval: Duration
  private(set) var trail: [Int]
  private(set) var isRunning = false
  @ObservationIgnored private let sleep: PreviewSleep
  @ObservationIgnored private var task: Task<Void, Never>?

  init(
    restingColumn: Int, alternateColumn: Int, interval: Duration,
    sleep: @escaping PreviewSleep = PreviewClock.live
  ) {
    self.restingColumn = restingColumn
    self.alternateColumn = alternateColumn
    self.interval = interval
    self.sleep = sleep
    trail = [restingColumn]
  }

  var focusedColumn: Int { trail.last ?? restingColumn }

  func start(reduceMotion: Bool) {
    stop()
    guard !reduceMotion else { return }
    isRunning = true
    task = Task { await run() }
  }

  func stop() {
    task?.cancel()
    task = nil
    isRunning = false
    trail = [restingColumn]
  }

  func run() async {
    while !Task.isCancelled {
      do {
        try await sleep(interval)
      } catch {
        return
      }
      advance()
    }
  }

  func advance() {
    let next = focusedColumn == restingColumn ? alternateColumn : restingColumn
    trail = Array((trail + [next]).suffix(PreviewMetrics.Sample.focusTrailLength))
  }
}
