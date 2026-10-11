import CoreGraphics

struct TileabilityCache {
  static let rejectionLifetime = Duration.seconds(1)

  private let now: () -> ContinuousClock.Instant
  private var accepted: Set<CGWindowID> = []
  private var rejections: [CGWindowID: ContinuousClock.Instant] = [:]

  init(now: @escaping () -> ContinuousClock.Instant) {
    self.now = now
  }

  func answer(for window: CGWindowID) -> Bool? {
    if accepted.contains(window) { return true }
    guard let rejectedAt = rejections[window],
      rejectedAt.duration(to: now()) < Self.rejectionLifetime
    else { return nil }
    return false
  }

  mutating func record(_ window: CGWindowID, isTileable: Bool) {
    if isTileable {
      rejections[window] = nil
      accepted.insert(window)
    } else {
      rejections[window] = now()
    }
  }

  mutating func retain(only alive: Set<CGWindowID>) {
    accepted.formIntersection(alive)
    rejections = rejections.filter { alive.contains($0.key) }
  }
}
