import CoreGraphics
import StripCore

@testable import Macousel

@MainActor
final class FakeWindowCapture: WindowCapture {
  var isPermitted = true
  private(set) var captured: [[WindowCaptureRequest]] = []
  private(set) var permissionRequests = 0

  func requestPermission() {
    permissionRequests += 1
  }

  func capture(_ requests: [WindowCaptureRequest]) -> AsyncStream<(WindowID, CGImage)> {
    captured.append(requests)
    let images = requests.compactMap { request in Self.image().map { (request.window, $0) } }
    return AsyncStream { continuation in
      for image in images { continuation.yield(image) }
      continuation.finish()
    }
  }

  private static func image() -> CGImage? {
    CGContext(
      data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?.makeImage()
  }
}
