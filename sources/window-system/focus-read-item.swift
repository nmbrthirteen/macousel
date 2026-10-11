import CoreGraphics

public nonisolated struct FocusReadItem: Sendable {
  public let pid: pid_t
  public let read: @Sendable () -> CGWindowID?

  public init(pid: pid_t, read: @escaping @Sendable () -> CGWindowID?) {
    self.pid = pid
    self.read = read
  }
}
