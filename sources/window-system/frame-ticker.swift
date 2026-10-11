import AppKit
import QuartzCore

public final class FrameTicker {
  public var onFrame: ((_ deltaTime: Double) -> Void)?

  private var link: CADisplayLink?
  private var lastTimestamp: CFTimeInterval?
  private let target = Target()

  public init() {
    target.owner = self
  }

  public var isRunning: Bool {
    link != nil
  }

  public func start() {
    guard link == nil,
      let screen = NSScreen.screens.max(by: {
        $0.maximumFramesPerSecond < $1.maximumFramesPerSecond
      })
    else { return }
    let link = screen.displayLink(target: target, selector: #selector(Target.tick(_:)))
    link.add(to: .main, forMode: .common)
    lastTimestamp = nil
    self.link = link
  }

  public func stop() {
    link?.invalidate()
    link = nil
    lastTimestamp = nil
  }

  fileprivate func tick(_ link: CADisplayLink) {
    let delta = lastTimestamp.map { link.timestamp - $0 } ?? (link.targetTimestamp - link.timestamp)
    lastTimestamp = link.timestamp
    onFrame?(delta)
  }

  private final class Target: NSObject {
    weak var owner: FrameTicker?

    @objc func tick(_ link: CADisplayLink) {
      owner?.tick(link)
    }
  }
}
