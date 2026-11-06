import CoreGraphics
import StripCore

@testable import Macousel

@MainActor
final class FakeWindowCapture: WindowCapture {
  var isPermitted = true
  var frames: [WindowID: CGRect] = [:]
  // Windows whose picture never arrives, as when ScreenCaptureKit stalls on one window.
  var stalled: Set<WindowID> = []
  private(set) var captured: [[WindowCaptureRequest]] = []
  private(set) var desktops: [DesktopCaptureRequest] = []
  private(set) var permissionRequests = 0

  func requestPermission() {
    permissionRequests += 1
  }

  func capture(_ requests: [WindowCaptureRequest], desktop: DesktopCaptureRequest?)
    -> AsyncStream<WindowCapturePicture>
  {
    captured.append(requests)
    if let desktop { desktops.append(desktop) }
    var pictures = requests.filter { !stalled.contains($0.window) }.compactMap { request in
      Self.image().map {
        WindowCapturePicture.window(request.window, $0, frame: frames[request.window] ?? .zero)
      }
    }
    if desktop != nil, let image = Self.image() { pictures.append(.desktop(image)) }
    let finishes = stalled.isDisjoint(with: requests.map(\.window))
    return AsyncStream { continuation in
      for picture in pictures { continuation.yield(picture) }
      if finishes { continuation.finish() }
    }
  }

  private static func image() -> CGImage? {
    CGContext(
      data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?.makeImage()
  }
}
