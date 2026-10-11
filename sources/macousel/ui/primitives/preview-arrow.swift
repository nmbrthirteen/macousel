import StripCore
import SwiftUI

struct PreviewArrow: Shape {
  let direction: StripCore.HorizontalDirection
  let headSize: Double

  func path(in rect: CGRect) -> Path {
    let tip = direction == .left ? rect.minX : rect.maxX
    let tail = direction == .left ? rect.maxX : rect.minX
    let back = direction == .left ? tip + headSize : tip - headSize
    var path = Path()
    path.move(to: CGPoint(x: tail, y: rect.midY))
    path.addLine(to: CGPoint(x: tip, y: rect.midY))
    path.move(to: CGPoint(x: back, y: rect.midY - headSize))
    path.addLine(to: CGPoint(x: tip, y: rect.midY))
    path.addLine(to: CGPoint(x: back, y: rect.midY + headSize))
    return path
  }
}
