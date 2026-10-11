import CoreGraphics
import StripCore

struct DragResize {
  static let tolerance: CGFloat = 2

  let state: TilingState

  static func hasResized(from start: CGRect, to end: CGRect) -> Bool {
    abs(end.width - start.width) > tolerance || abs(end.height - start.height) > tolerance
  }

  func commit(_ window: WindowID, in key: Workspace.Key, from start: CGRect, to end: CGRect)
    -> DragBranch
  {
    let resizedWidth = abs(end.width - start.width) > Self.tolerance
    let resizedHeight = abs(end.height - start.height) > Self.tolerance
    if resizedWidth {
      state.workspaces[key]?.strip.setFixedWidth(end.width, of: window)
    }
    if resizedHeight, let display = state.display(for: key) {
      let draggedTopEdge = abs(end.minY - start.minY) > Self.tolerance
      state.workspaces[key]?.strip.setHeight(
        end.height, of: window, borrowingFrom: draggedTopEdge ? .above : .below,
        viewportHeight: display.visibleFrame.height, config: state.config)
    }
    state.scrollToFocus(key)
    return resizedWidth && resizedHeight
      ? .resizedWidthAndHeight : resizedWidth ? .resizedWidth : .resizedHeight
  }
}
