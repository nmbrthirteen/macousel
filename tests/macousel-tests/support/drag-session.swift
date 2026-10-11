import CoreGraphics
import Testing

@testable import Macousel

@MainActor
struct DragSession {
  let fixture: ControllerFixture
  let window: FakeWindow
  private let grabOffset: CGVector
  private let size: CGSize

  init(_ window: FakeWindow, in fixture: ControllerFixture, atX share: Double = 0.5) throws {
    let source = fixture.source
    fixture.pointer.windowAtPoint = { point in
      source.windows.keys.sorted().first {
        source.fakeWindow($0)?.serverFrame?.contains(point) == true
      }
    }
    let frame = try #require(window.serverFrame)
    let grab = CGPoint(x: frame.minX + frame.width * share, y: frame.midY)
    self.fixture = fixture
    self.window = window
    grabOffset = CGVector(dx: grab.x - frame.minX, dy: grab.y - frame.minY)
    size = frame.size
    fixture.pointer.pressPrimary(at: grab)
  }

  func move(to point: CGPoint) {
    window.frame = CGRect(
      origin: CGPoint(x: point.x - grabOffset.dx, y: point.y - grabOffset.dy), size: size)
    fixture.pointer.dragPrimary(to: point)
  }

  func moveSilently(to point: CGPoint) {
    window.frame = CGRect(
      origin: CGPoint(x: point.x - grabOffset.dx, y: point.y - grabOffset.dy), size: size)
    fixture.pointer.movePrimarySilently(to: point)
  }

  func resizeSilently(to frame: CGRect, pointerAt point: CGPoint) {
    window.frame = frame
    fixture.pointer.movePrimarySilently(to: point)
  }

  func letPollingRun(frames: Int = 2) {
    for _ in 0..<frames { fixture.clock.advance(by: DragPoller.interval) }
  }

  func resize(to frame: CGRect, pointerAt point: CGPoint) {
    window.frame = frame
    fixture.pointer.dragPrimary(to: point)
  }

  @discardableResult
  func release(sendingEvent: Bool = true) -> CGRect? {
    let preview = fixture.overlays.dropPreview
    fixture.pointer.releasePrimary(sendingEvent: sendingEvent)
    return preview
  }
}
