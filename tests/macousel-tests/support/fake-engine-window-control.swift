import CoreGraphics

@testable import Macousel

@MainActor
final class FakeEngineWindowControl: EngineWindowControl {
  private(set) var raised: [[CGWindowID]] = []
  private(set) var focused: [CGWindowID] = []
  private(set) var moved: [CGWindowID: CGRect] = [:]

  func raise(_ windows: [CGWindowID]) {
    raised.append(windows)
  }

  func focus(_ window: CGWindowID) {
    focused.append(window)
  }

  func move(_ window: CGWindowID, to frame: CGRect) {
    moved[window] = frame
  }
}
