enum OverlayTextStyle {
  case small, regular, large

  var size: Double {
    switch self {
    case .small: Metrics.Overlay.smallText
    case .regular: Metrics.Overlay.regularText
    case .large: Metrics.Overlay.largeText
    }
  }
}
