import Dispatch

public final class WindowFactsReader {
  public static let deadline = DispatchTimeInterval.milliseconds(300)

  private let deadline: DispatchTimeInterval
  private var queues: [pid_t: DispatchQueue] = [:]

  public init(deadline: DispatchTimeInterval = WindowFactsReader.deadline) {
    self.deadline = deadline
  }

  public func read(
    _ items: [WindowReadItem], focus: FocusReadItem?,
    completion: @escaping @MainActor (WindowProbeResult) -> Void
  ) {
    var groups = Dictionary(grouping: items, by: \.pid)
    if let focus, groups[focus.pid] == nil { groups[focus.pid] = [] }
    let deliver: @Sendable (WindowProbeResult) -> Void = { result in
      DispatchQueue.main.async { MainActor.assumeIsolated { completion(result) } }
    }
    guard !groups.isEmpty else {
      deliver(WindowProbeResult())
      return
    }
    let batch = ProbeBatch(waiting: groups.mapValues { $0.map(\.id) }, deliver: deliver)
    for (pid, group) in groups {
      let groupFocus = focus?.pid == pid ? focus : nil
      queue(for: pid).async {
        let outcome = GroupReading.run(items: group, focus: groupFocus)
        batch.finish(pid: pid, facts: outcome.facts, focusedWindow: outcome.focusedWindow)
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + deadline) { batch.expire() }
  }

  private func queue(for pid: pid_t) -> DispatchQueue {
    if let queue = queues[pid] { return queue }
    let queue = DispatchQueue(label: "dev.macousel.window-facts.\(pid)", qos: .userInitiated)
    queues[pid] = queue
    return queue
  }
}
