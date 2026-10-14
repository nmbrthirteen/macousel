import SwiftUI

struct SceneWindowContent: View {
  private static let inset = 8.0
  private static let lineHeight = 4.0
  private static let lineGap = 6.0
  private static let lineShares = [0.9, 0.75, 0.82, 0.6, 0.88, 0.7, 0.8, 0.5, 0.85, 0.65]
  private static let sidebarShare = 0.3
  private static let galleryColumns = 3
  private static let galleryTints: [Color] = [.orange, .pink, .teal, .indigo, .mint, .purple]
  private static let bubbleHeight = 12.0

  let style: SceneWindowStyle

  var body: some View {
    Canvas { context, size in
      let area = CGRect(origin: .zero, size: size).insetBy(dx: Self.inset, dy: Self.inset / 2)
      switch style {
      case .document: lines(in: area, tint: .primary.opacity(0.12), into: context)
      case .sidebar: sidebar(in: area, into: context)
      case .console: lines(in: area, tint: .green.opacity(0.55), into: context)
      case .gallery: gallery(in: area, into: context)
      case .chat: chat(in: area, into: context)
      }
    }
  }

  private func lines(in area: CGRect, tint: Color, into context: GraphicsContext) {
    var y = area.minY
    for share in Self.lineShares where y + Self.lineHeight <= area.maxY {
      let line = CGRect(x: area.minX, y: y, width: area.width * share, height: Self.lineHeight)
      context.fill(Capsule().path(in: line), with: .color(tint))
      y += Self.lineHeight + Self.lineGap
    }
  }

  private func sidebar(in area: CGRect, into context: GraphicsContext) {
    let split = area.width * Self.sidebarShare
    let rail = CGRect(x: area.minX, y: area.minY, width: split - Self.inset, height: area.height)
    context.fill(
      RoundedRectangle(cornerRadius: Self.lineHeight).path(in: rail),
      with: .color(.accentColor.opacity(0.14)))
    lines(
      in: CGRect(x: area.minX + split, y: area.minY, width: area.width - split, height: area.height),
      tint: .primary.opacity(0.12), into: context)
  }

  private func gallery(in area: CGRect, into context: GraphicsContext) {
    let side = (area.width - Self.lineGap * Double(Self.galleryColumns - 1)) / Double(Self.galleryColumns)
    var index = 0
    var y = area.minY
    while y + side <= area.maxY + side / 2 {
      for column in 0..<Self.galleryColumns {
        let tile = CGRect(
          x: area.minX + Double(column) * (side + Self.lineGap), y: y, width: side,
          height: min(side, area.maxY - y))
        let tint = Self.galleryTints[index % Self.galleryTints.count]
        context.fill(
          RoundedRectangle(cornerRadius: Self.lineHeight).path(in: tile), with: .color(tint.opacity(0.55)))
        index += 1
      }
      y += side + Self.lineGap
    }
  }

  private func chat(in area: CGRect, into context: GraphicsContext) {
    var y = area.minY
    var isMine = false
    for share in Self.lineShares where y + Self.bubbleHeight <= area.maxY {
      let width = area.width * share * 0.6
      let bubble = CGRect(
        x: isMine ? area.maxX - width : area.minX, y: y, width: width, height: Self.bubbleHeight)
      context.fill(
        Capsule().path(in: bubble),
        with: .color(isMine ? .accentColor.opacity(0.8) : .primary.opacity(0.1)))
      y += Self.bubbleHeight + Self.lineGap
      isMine.toggle()
    }
  }
}
