import CoreGraphics

public nonisolated struct WindowFacts: Sendable, Equatable {
  public static let unanswered = WindowFacts(
    isTileable: false, isFullScreen: false, frame: nil, title: "", timedOut: true)

  public var isTileable: Bool
  public var isFullScreen: Bool
  public var frame: CGRect?
  public var title: String
  public var timedOut: Bool

  public init(
    isTileable: Bool, isFullScreen: Bool, frame: CGRect?, title: String, timedOut: Bool
  ) {
    self.isTileable = isTileable
    self.isFullScreen = isFullScreen
    self.frame = frame
    self.title = title
    self.timedOut = timedOut
  }
}
