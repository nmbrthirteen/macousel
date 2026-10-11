import CoreGraphics

public struct MotionField: Sendable, Equatable {
  private struct PointSpring: Sendable, Equatable {
    var x: Spring
    var y: Spring

    init(at origin: CGPoint, response: Double) {
      x = Spring(value: origin.x, response: response)
      y = Spring(value: origin.y, response: response)
    }

    var origin: CGPoint { CGPoint(x: x.value, y: y.value) }
    var isSettled: Bool { x.isSettled && y.isSettled }

    mutating func retarget(to origin: CGPoint, launch: Double) {
      x.retarget(to: origin.x, launch: launch)
      y.retarget(to: origin.y, launch: launch)
    }

    mutating func advance(by deltaTime: Double) {
      x.advance(by: deltaTime)
      y.advance(by: deltaTime)
    }

    mutating func snap() {
      x.snap()
      y.snap()
    }

    func rebuilt(response: Double) -> PointSpring {
      var rebuilt = PointSpring(at: origin, response: response)
      rebuilt.retarget(to: CGPoint(x: x.target, y: y.target), launch: 0)
      rebuilt.x.velocity = x.velocity
      rebuilt.y.velocity = y.velocity
      return rebuilt
    }
  }

  public static let standardResponse = 0.28
  public static let launch = 0.85

  public private(set) var response: Double
  private var springs: [WindowID: PointSpring] = [:]

  public init(response: Double = MotionField.standardResponse) {
    self.response = response
  }

  public var isSettled: Bool {
    springs.values.allSatisfy(\.isSettled)
  }

  public mutating func setResponse(_ response: Double) {
    guard response != self.response else { return }
    self.response = response
    springs = springs.mapValues { $0.rebuilt(response: response) }
  }

  public func isTracking(_ window: WindowID) -> Bool {
    springs[window] != nil
  }

  public mutating func retarget(
    to layout: StripLayout, snapping: Bool = false, entering origins: [WindowID: CGPoint] = [:]
  ) {
    var retained: [WindowID: PointSpring] = [:]
    retained.reserveCapacity(layout.placements.count)
    for placement in layout.placements {
      let start = origins[placement.window] ?? placement.frame.origin
      var spring = springs[placement.window] ?? PointSpring(at: start, response: response)
      spring.retarget(to: placement.frame.origin, launch: Self.launch)
      if snapping { spring.snap() }
      retained[placement.window] = spring
    }
    springs = retained
  }

  public mutating func advance(by deltaTime: Double) {
    for window in springs.keys {
      springs[window]?.advance(by: deltaTime)
    }
  }

  public mutating func snap() {
    for window in springs.keys {
      springs[window]?.snap()
    }
  }

  public mutating func impart(horizontalVelocity: Double) {
    for window in springs.keys {
      springs[window]?.x.velocity += horizontalVelocity
    }
  }

  public func animated(_ layout: StripLayout, in viewport: CGRect) -> StripLayout {
    var animated = layout
    animated.placements = layout.placements.map { placement in
      guard let origin = springs[placement.window]?.origin else { return placement }
      return placement.moved(to: origin, in: viewport)
    }
    return animated
  }
}

extension Placement {
  public func moved(to origin: CGPoint, in viewport: CGRect) -> Placement {
    var moved = self
    moved.frame.origin = CGPoint(x: origin.x.rounded(), y: origin.y.rounded())
    moved.visibility = Strip.visibility(of: moved.frame, in: viewport)
    return moved
  }
}
