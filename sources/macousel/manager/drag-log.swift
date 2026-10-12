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

  func released(_ window: CGWindowID, at point: CGPoint, rowsPerColumn: [Int]) {
    let rows = rowsPerColumn.map(String.init).joined(separator: " ")
    Self.logger.info(
      """
      drag release: window \(window, privacy: .public) at x \(Int(point.x), privacy: .public) \
      y \(Int(point.y), privacy: .public), rows per column \(rows, privacy: .public)
      """)
  }

  func unsettled(_ window: CGWindowID) {
    Self.logger.info(
      "drag ended: window \(window, privacy: .public) structure did not settle, nothing moved")
  }

  func skipped(_ window: CGWindowID, reason: String) {
    Self.logger.info(
      "drag ended: window \(window, privacy: .public) nothing moved, \(reason, privacy: .public)")
  }

  func aborted(_ window: CGWindowID, step: String) {
    Self.logger.info(
      "drag ended: window \(window, privacy: .public) aborted at \(step, privacy: .public)")
  }

  func snapped(_ window: CGWindowID, reason: String) {
    Self.logger.info(
      "drag snap: window \(window, privacy: .public) \(reason, privacy: .public)")
  }

  func centered(_ window: CGWindowID) {
    Self.logger.info("drag center: window \(window, privacy: .public) strip centered")
  }

  func ignoredPress(reason: String) {
    Self.logger.info("drag press ignored: \(reason, privacy: .public)")
  }
}
