import CoreGraphics
import os

struct DragLog {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "drag")

  func recognised(_ window: CGWindowID, as kind: LiveDrag.Kind) {
    let name = kind == .move ? "move" : "resize"
    Self.logger.info(
      "drag recognised: window \(window, privacy: .public) \(name, privacy: .public)")
  }

  func ended(_ window: CGWindowID, as branch: DragBranch) {
    Self.logger.info(
      """
      drag ended: window \(window, privacy: .public) \(branch.logName, privacy: .public), \
      target \(branch.targetKind, privacy: .public)
      """)
  }
}
