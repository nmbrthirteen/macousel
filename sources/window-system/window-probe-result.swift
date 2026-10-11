import CoreGraphics

public nonisolated struct WindowProbeResult: Sendable, Equatable {
  public var facts: [CGWindowID: WindowFacts]
  public var focusedWindow: CGWindowID?

  public init(facts: [CGWindowID: WindowFacts] = [:], focusedWindow: CGWindowID? = nil) {
    self.facts = facts
    self.focusedWindow = focusedWindow
  }
}
