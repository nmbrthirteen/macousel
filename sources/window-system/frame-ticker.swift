import AppKit
import QuartzCore

public final class FrameTicker {
  public var onFrame: ((_ deltaTime: Double) -> Void)?

  private static let fallbackFramesPerSecond = 60

  private var link: CADisplayLink?
  private var isActive = false
  private var lastTimestamp: CFTimeInterval?
  private var measuredInterval: Double?
  private var screenObserver: NSObjectProtocol?
  private let target = Target()

  public init() {
    target.owner = self
    screenObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated { self?.screensChanged() }
    }
  }

  public var isRunning: Bool {
    isActive
  }

  public var frameInterval: Double {
    measuredInterval ?? 1 / Double(Self.fastestScreenRate)
  }

  public func start() {
    guard !isActive, let link = link ?? makeLink() else { return }
    self.link = link
    isActive = true
    lastTimestamp = nil
    link.isPaused = false
  }

  public func stop() {
    isActive = false
    link?.isPaused = true
    lastTimestamp = nil
  }

  private static var fastestScreenRate: Int {
    NSScreen.screens.map(\.maximumFramesPerSecond).max() ?? fallbackFramesPerSecond
  }

  private func makeLink() -> CADisplayLink? {
    guard
      let screen = NSScreen.screens.max(by: {
        $0.maximumFramesPerSecond < $1.maximumFramesPerSecond
      })
    else { return nil }
    let link = screen.displayLink(target: target, selector: #selector(Target.tick(_:)))
    link.isPaused = true
    link.add(to: .main, forMode: .common)
    return link
  }

  private func screensChanged() {
    link?.invalidate()
    link = nil
    lastTimestamp = nil
    measuredInterval = nil
    guard isActive else { return }
    link = makeLink()
    link?.isPaused = false
    isActive = link != nil
  }

  fileprivate func tick(_ link: CADisplayLink) {
    let interval = link.targetTimestamp - link.timestamp
    if interval > 0 { measuredInterval = interval }
    let delta = lastTimestamp.map { link.timestamp - $0 } ?? interval
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
