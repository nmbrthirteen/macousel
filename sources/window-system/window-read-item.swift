import CoreGraphics

public nonisolated struct WindowReadItem: Sendable {
  public let id: CGWindowID
  public let pid: pid_t
  public let read: @Sendable () -> WindowFacts

  public init(id: CGWindowID, pid: pid_t, read: @escaping @Sendable () -> WindowFacts) {
    self.id = id
    self.pid = pid
    self.read = read
  }
}
