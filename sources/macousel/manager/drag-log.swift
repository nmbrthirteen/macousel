import CoreGraphics
import os

struct DragLog {
  private static let logger = Logger(subsystem: "dev.macousel.app", category: "drag")

  func recognised(_ window: CGWindowID) {
    Self.logger.info("drag recognised: window \(window, privacy: .public)")
  }

  func ended(_ window: CGWindowID, as branch: DragBranch, pointerFraction: Double?) {
    guard branch.reportsPointerPosition else {
      Self.logger.info(
        "drag ended: window \(window, privacy: .public) \(branch.logName, privacy: .public)")
      return
    }
    let position =
      pointerFraction.map { Self.description(of: $0) } ?? "pointer over no window"
    Self.logger.info(
      """
      drag ended: window \(window, privacy: .public) \(branch.logName, privacy: .public), \
      \(position, privacy: .public)
      """)
  }

  private static func description(of fraction: Double) -> String {
    let text = fraction.formatted(.number.precision(.fractionLength(2)))
    return "pointer at \(text) of the window under it"
  }
}
