import CoreGraphics
import WindowSystem

struct EngineCentering {
  private struct Placement: Equatable {
    var window: Int32
    var frame: EngineWindow.Frame?
  }

  static let restingPolls = 3
  static let landingRadius: CGFloat = 24
  static let warpPolls = 40
  static let warpInterval = Duration.milliseconds(10)

  let commands: any EngineCommanding
  let pointer: any PointerDevice
  let displays: () -> [Display]
  let isEnabled: () -> Bool
  let sleep: (Duration) async throws -> Void
  var now: () -> ContinuousClock.Instant = { ContinuousClock.now }

  func centerFocusedColumn() async -> Bool {
    guard isEnabled(), let display = await restingDisplay() else { return false }
    let landing = CGPoint(x: display.frame.midX, y: display.frame.midY)
    var resting = pointer.location
    await commands.send(["window", "center"])
    guard !Self.isNear(resting, landing) else { return true }
    for _ in 0..<Self.warpPolls {
      let location = pointer.location
      if Self.isNear(location, landing) {
        pointer.warp(to: resting)
        return true
      }
      resting = location
      do {
        try await sleep(Self.warpInterval)
      } catch {
        return true
      }
    }
    return true
  }

  private func restingDisplay() async -> Display? {
    var previous: [Placement] = []
    var steadyPolls = 0
    var resting: EngineSnapshot?
    let poll = EnginePoll(commands: commands, sleep: sleep, now: now)
    let rested = await poll.until { snapshot in
      let placements = snapshot.tiledWindows.map { Placement(window: $0.windowId, frame: $0.frame) }
      steadyPolls = placements == previous ? steadyPolls + 1 : 1
      previous = placements
      resting = snapshot
      return steadyPolls >= Self.restingPolls && snapshot.focusedWindow != nil
    }
    return rested ? resting?.display(in: displays()) : nil
  }

  private static func isNear(_ point: CGPoint, _ other: CGPoint) -> Bool {
    hypot(point.x - other.x, point.y - other.y) <= landingRadius
  }
}
