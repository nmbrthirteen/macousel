import CoreGraphics
import StripCore
import Testing

enum DropZone: CaseIterable, CustomTestStringConvertible {
  case stackAbove, stackBelow, beforeColumn, afterColumn, gap, pastLast

  var testDescription: String { String(describing: self) }

  var draggedIndex: Int { self == .beforeColumn ? 2 : 0 }

  func point(among frames: [CGRect]) -> CGPoint {
    switch self {
    case .stackAbove: CGPoint(x: frames[2].midX, y: frames[2].minY + 10)
    case .stackBelow: CGPoint(x: frames[2].midX, y: frames[2].maxY - 10)
    case .beforeColumn: CGPoint(x: frames[1].minX + 10, y: frames[1].midY)
    case .afterColumn: CGPoint(x: frames[2].maxX - 10, y: frames[2].midY)
    case .gap: CGPoint(x: (frames[1].maxX + frames[2].minX) / 2, y: frames[1].midY)
    case .pastLast: CGPoint(x: frames[2].maxX + 100, y: frames[2].midY)
    }
  }

  func apply(to strip: inout Strip) {
    switch self {
    case .stackAbove: strip.stack(WindowID(1), ontoColumnOf: WindowID(3), atRow: 0)
    case .stackBelow: strip.stack(WindowID(1), ontoColumnOf: WindowID(3), atRow: 1)
    case .beforeColumn: strip.move(WindowID(3), toColumn: 1)
    case .afterColumn: strip.move(WindowID(1), toColumn: 2)
    case .gap: strip.move(WindowID(1), toColumn: 1)
    case .pastLast: strip.move(WindowID(1), toColumn: 2)
    }
  }
}
