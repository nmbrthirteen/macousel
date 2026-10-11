import CoreGraphics

public nonisolated struct TapMouseEvent: Sendable, Equatable {
  public enum Kind: Sendable { case pressed, dragged, released }

  public let kind: Kind
  public let location: CGPoint

  public init(kind: Kind, location: CGPoint) {
    self.kind = kind
    self.location = location
  }
}
