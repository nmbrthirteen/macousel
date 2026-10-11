import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
extension MinimapModel {
  var geometry: MinimapGeometry {
    MinimapGeometry(snapshot: snapshot)
  }

  func cell(_ window: UInt32) throws -> MinimapCell {
    try #require(geometry.cells.first { $0.window == WindowID(window) })
  }

  func drag(from start: CGPoint, to end: CGPoint) {
    pressed(at: start)
    dragged(to: end)
    released(at: end)
  }

  func click(_ point: CGPoint) {
    pressed(at: point)
    released(at: point)
  }
}
