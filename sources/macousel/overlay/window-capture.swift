import CoreGraphics
import StripCore

nonisolated struct WindowCaptureRequest: Equatable, Sendable {
  var window: WindowID
  var pixelSize: CGSize
}

// The display as it looks without the strip's windows. Laid under the window pictures, it hides
// the real windows from the first frame, so the pictures read as the windows themselves moving.
nonisolated struct DesktopCaptureRequest: Equatable, Sendable {
  var displayFrame: CGRect
  var backingScale: Double
  var excluding: [WindowID]
}

nonisolated enum WindowCapturePicture: Sendable {
  case window(WindowID, CGImage, frame: CGRect)
  case desktop(CGImage)
}

protocol WindowCapture {
  var isPermitted: Bool { get }
  func requestPermission()
  func capture(_ requests: [WindowCaptureRequest], desktop: DesktopCaptureRequest?)
    -> AsyncStream<WindowCapturePicture>
}
