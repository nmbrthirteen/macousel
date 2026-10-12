import CoreGraphics
import os

struct DragLog {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "drag")

  func pressed(_ window: CGWindowID, isTiled: Bool) {
    Self.logger.info(
      "drag press: window \(window, privacy: .public) tiled \(isTiled, privacy: .public) source tap"
    )
  }

  func recognised(_ window: CGWindowID, as kind: LiveDrag.Kind, noticedBy notice: DragNotice) {
    let name = kind == .move ? "move" : "resize"
    Self.logger.info(
      """
      drag recognised: window \(window, privacy: .public) \(name, privacy: .public), \
      noticed by \(notice.logName, privacy: .public)
      """)
  }

  func ended(_ window: CGWindowID, as branch: DragBranch) {
    Self.logger.info(
      """
      drag ended: window \(window, privacy: .public) \(branch.logName, privacy: .public), \
      target \(branch.targetKind, privacy: .public)
      """)
  }

  func unsettled(_ window: CGWindowID) {
    Self.logger.info(
      "drag ended: window \(window, privacy: .public) structure did not settle, nothing moved")
  }
}
