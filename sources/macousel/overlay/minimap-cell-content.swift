import CoreGraphics

struct MinimapCellContent: Equatable {
  let icon: MinimapCellIcon?
  let number: MinimapCellNumber?

  static let empty = MinimapCellContent(icon: nil, number: nil)

  private init(icon: MinimapCellIcon?, number: MinimapCellNumber?) {
    self.icon = icon
    self.number = number
  }

  init(area: CGRect, columnNumber: Int, isLeadRow: Bool, bundleIdentifier: String?) {
    let center = CGPoint(x: area.midX, y: area.midY)
    let iconBundle = bundleIdentifier.flatMap { identifier in
      area.width >= Metrics.Minimap.iconMinimumWidth
        && area.height >= Metrics.Minimap.iconMinimumHeight ? identifier : nil
    }
    guard isLeadRow, (1...Metrics.Minimap.highestNumberedColumn).contains(columnNumber) else {
      self.init(icon: iconBundle.map { MinimapCellIcon(bundleIdentifier: $0, center: center) }, number: nil)
      return
    }
    if let iconBundle, area.width >= Metrics.Minimap.pairMinimumWidth {
      let pairWidth =
        Metrics.Minimap.iconSide + Metrics.Minimap.pairGap + Metrics.Minimap.numberSlotWidth
      let left = area.midX - pairWidth / 2
      self.init(
        icon: MinimapCellIcon(
          bundleIdentifier: iconBundle,
          center: CGPoint(x: left + Metrics.Minimap.iconSide / 2, y: center.y)),
        number: MinimapCellNumber(
          value: columnNumber,
          center: CGPoint(
            x: left + pairWidth - Metrics.Minimap.numberSlotWidth / 2, y: center.y)))
    } else if area.width >= Metrics.Minimap.numberMinimumWidth,
      area.height >= Metrics.Minimap.numberMinimumHeight
    {
      self.init(icon: nil, number: MinimapCellNumber(value: columnNumber, center: center))
    } else {
      self = .empty
    }
  }
}
