import CoreGraphics
import StripCore

nonisolated struct WindowCaptureRequest: Equatable, Sendable {
  var window: WindowID
  var pixelSize: CGSize
}

protocol WindowCapture {
  var isPermitted: Bool { get }
  func requestPermission()
  func capture(_ requests: [WindowCaptureRequest]) -> AsyncStream<(WindowID, CGImage)>
}
