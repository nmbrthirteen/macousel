import CoreGraphics

final class AdmissionFrames {
  private var frames: [CGWindowID: CGRect] = [:]

  func record(_ frame: CGRect, for window: CGWindowID) {
    frames[window] = frame
  }

  func take(_ window: CGWindowID) -> CGRect? {
    frames.removeValue(forKey: window)
  }

  func clear() {
    frames = [:]
  }
}
