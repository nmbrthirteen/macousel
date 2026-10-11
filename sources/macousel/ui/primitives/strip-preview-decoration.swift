struct StripPreviewDecoration: Equatable {
  static let none = StripPreviewDecoration()

  var focusBorderWidth: Double?
  var dimAmount: Double?
  var floatingCard: FloatingPreviewCard?
}
