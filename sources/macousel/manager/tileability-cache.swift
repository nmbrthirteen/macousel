import CoreGraphics

struct TileabilityCache {
  static let rejectionLifetime = Duration.seconds(1)

  private let now: () -> ContinuousClock.Instant
  private var accepted: Set<CGWindowID> = []
  private var rejections: [CGWindowID: ContinuousClock.Instant] = [:]

  init(now: @escaping () -> ContinuousClock.Instant) {
    self.now = now
  }

  mutating func isTileable(_ window: any WindowHandle) -> Bool {
    if accepted.contains(window.id) { return true }
    if let rejectedAt = rejections[window.id],
      rejectedAt.duration(to: now()) < Self.rejectionLifetime
    {
      return false
    }
    guard window.isTileable else {
      rejections[window.id] = now()
      return false
    }
    rejections[window.id] = nil
    accepted.insert(window.id)
    return true
  }

  mutating func retain(only alive: Set<CGWindowID>) {
    accepted.formIntersection(alive)
    rejections = rejections.filter { alive.contains($0.key) }
  }
}
