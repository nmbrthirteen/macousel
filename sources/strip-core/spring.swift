import Foundation

public struct Spring: Sendable, Equatable {
  public var value: Double
  public var velocity: Double
  public var target: Double
  private let angularFrequency: Double

  static let restingVelocity = 5.0
  static let strongestLaunch = 1.0

  public init(value: Double, response: Double = 0.28) {
    precondition(response > 0, "response must be positive")
    self.value = value
    velocity = 0
    target = value
    angularFrequency = Self.angularFrequency(forResponse: response)
  }

  public mutating func retarget(to newTarget: Double, launch: Double = 0) {
    target = newTarget
    guard launch > 0 else { return }
    let launchVelocity = -min(launch, Self.strongestLaunch) * angularFrequency * (value - target)
    let alreadyFasterTowardTarget =
      velocity * launchVelocity > 0 && abs(velocity) >= abs(launchVelocity)
    if !alreadyFasterTowardTarget { velocity = launchVelocity }
  }

  public static func projectionTime(response: Double) -> Double {
    2 / angularFrequency(forResponse: response)
  }

  private static func angularFrequency(forResponse response: Double) -> Double {
    6 / response
  }

  public var isSettled: Bool {
    abs(value - target) < 0.5 && abs(velocity) < Self.restingVelocity
  }

  public mutating func advance(by dt: Double) {
    guard dt > 0 else { return }
    let omega = angularFrequency
    let distance = value - target
    let slope = velocity + omega * distance
    let decay = exp(-omega * dt)
    value = target + (distance + slope * dt) * decay
    velocity = (velocity - omega * slope * dt) * decay
  }

  public mutating func snap() {
    value = target
    velocity = 0
  }
}
