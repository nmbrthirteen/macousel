nonisolated struct TapVerdict: Equatable {
  var swallows: Bool
  var delivery: TapDelivery?

  static let ignored = TapVerdict(swallows: false, delivery: nil)
}
