public nonisolated struct AppResponsiveness: Sendable, Equatable {
  public static let slowSingleSetMilliseconds = 100.0
  public static let recentSetCount = 8
  public static let slowMedianMilliseconds = 6.0
  public static let recoveryStreakLength = 5
  public static let recoveryCeilingMilliseconds = 4.0

  public private(set) var isSlow = false
  private var recent: [Double] = []
  private var quickStreak = 0

  public init(isSlow: Bool = false) {
    self.isSlow = isSlow
  }

  public mutating func record(milliseconds: Double) {
    if isSlow {
      recoverIfQuick(milliseconds)
    } else {
      classify(milliseconds)
    }
  }

  private mutating func classify(_ milliseconds: Double) {
    recent.append(milliseconds)
    if recent.count > Self.recentSetCount { recent.removeFirst() }
    let stalled = milliseconds >= Self.slowSingleSetMilliseconds
    let consistentlyBusy = recent.count == Self.recentSetCount && median > Self.slowMedianMilliseconds
    guard stalled || consistentlyBusy else { return }
    isSlow = true
    recent = []
    quickStreak = 0
  }

  private mutating func recoverIfQuick(_ milliseconds: Double) {
    quickStreak = milliseconds < Self.recoveryCeilingMilliseconds ? quickStreak + 1 : 0
    guard quickStreak >= Self.recoveryStreakLength else { return }
    isSlow = false
    quickStreak = 0
  }

  private var median: Double {
    let sorted = recent.sorted()
    let upper = sorted.count / 2
    guard sorted.count.isMultiple(of: 2) else { return sorted[upper] }
    return (sorted[upper - 1] + sorted[upper]) / 2
  }
}
