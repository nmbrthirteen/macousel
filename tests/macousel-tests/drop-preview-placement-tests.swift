import CoreGraphics
import Testing

@testable import Macousel

@MainActor
struct DropPreviewPlacementTests {
  @Test func framesBecomeRelativeToTheAreaOrigin() {
    let placement = DropPreviewPlacement(area: CGRect(x: -1000, y: -200, width: 3000, height: 1200))

    let local = placement.localFrame(of: CGRect(x: -900, y: 100, width: 400, height: 300))

    #expect(local == CGRect(x: 100, y: 300, width: 400, height: 300))
  }
}
