import AppKit
import SwiftUI

extension View {
  @ViewBuilder
  func glassContainer(spacing: CGFloat) -> some View {
    if #available(macOS 26, *) {
      GlassEffectContainer(spacing: spacing) { self }
    } else {
      self
    }
  }

  @ViewBuilder
  func resizePointer(_ axis: Axis) -> some View {
    if #available(macOS 15, *) {
      pointerStyle(axis == .horizontal ? .columnResize : .rowResize)
    } else {
      onHover { inside in
        if inside {
          (axis == .horizontal ? NSCursor.resizeLeftRight : NSCursor.resizeUpDown).push()
        } else {
          NSCursor.pop()
        }
      }
    }
  }
}
