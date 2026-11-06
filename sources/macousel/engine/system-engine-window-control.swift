import CoreGraphics
import WindowSystem

final class SystemEngineWindowControl: EngineWindowControl {
  func raise(_ windows: [CGWindowID]) {
    for id in windows { ManagedWindow.lookUp(id)?.raise() }
  }

  func focus(_ window: CGWindowID) {
    ManagedWindow.lookUp(window)?.focus()
  }

  func move(_ window: CGWindowID, to frame: CGRect) {
    ManagedWindow.lookUp(window)?.setFrame(frame)
  }
}
