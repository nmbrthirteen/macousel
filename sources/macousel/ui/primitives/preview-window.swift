import CoreGraphics
import StripCore

struct PreviewWindow: Identifiable, Equatable {
  let id: WindowID
  let rect: CGRect
  let isFocused: Bool
  let column: Int
  let row: Int
}
