extension Duration {
  nonisolated var fractionalMilliseconds: Double {
    let parts = components
    return Double(parts.seconds) * 1_000 + Double(parts.attoseconds) / 1e15
  }
}
