import Foundation
import os

private let logger = Logger(subsystem: "dev.macousel.app", category: "swipe-gesture-monitor")

private struct WeakMonitor {
  weak var monitor: SwipeGestureMonitor?
}

private var activeMonitors: [WeakMonitor] = []

private nonisolated func contactFrameCallback(
  _ device: UnsafeMutableRawPointer, _ touches: UnsafeMutableRawPointer, _ count: Int32,
  _ timestamp: Double, _ frame: Int32
) -> Int32 {
  let records = touches.assumingMemoryBound(to: MTTouch.self)
  var fingers = 0
  var sumX: Float = 0
  var sumY: Float = 0
  for index in 0..<Int(max(count, 0)) {
    let touch = records[index]
    guard touch.state == mtTouchStateMake || touch.state == mtTouchStateTouching else { continue }
    fingers += 1
    sumX += touch.positionX
    sumY += touch.positionY
  }
  let count = fingers
  let x = fingers > 0 ? Double(sumX) / Double(fingers) : 0
  let y = fingers > 0 ? Double(sumY) / Double(fingers) : 0
  DispatchQueue.main.async {
    MainActor.assumeIsolated {
      activeMonitors.removeAll { $0.monitor == nil }
      for entry in activeMonitors { entry.monitor?.handle(fingers: count, x: x, y: y) }
    }
  }
  return 0
}

public final class SwipeGestureMonitor {
  private static let decisionDistance = 0.02
  private static let horizontalRatio = 1.5

  private enum Candidate {
    case idle
    case undecided(startX: Double, startY: Double)
    case swiping(lastX: Double)
    case ignored
  }

  private struct Api {
    let unregister: MTRegisterFunction
    let stopDevice: MTDeviceStopFunction
  }

  public var fingerCount = 3
  public var onSwipe: ((_ deltaX: Double, _ phase: ScrollGestureTap.Phase) -> Void)?

  private var api: Api?
  private var devices: CFArray?
  private var candidate = Candidate.idle

  public init() {}

  public func start() -> Bool {
    if api != nil { return true }
    guard MemoryLayout<MTTouch>.size == mtTouchSize,
      MemoryLayout<MTTouch>.offset(of: \.state) == 20,
      MemoryLayout<MTTouch>.offset(of: \.positionX) == 32,
      MemoryLayout<MTTouch>.offset(of: \.positionY) == 36
    else {
      logger.error("MTTouch layout is \(MemoryLayout<MTTouch>.size) bytes, expected \(mtTouchSize)")
      return false
    }
    guard let handle = dlopen(multitouchFrameworkPath, RTLD_LAZY) else {
      logger.error("MultitouchSupport could not be loaded")
      return false
    }
    guard
      let createList: MTDeviceCreateListFunction = Self.symbol("MTDeviceCreateList", in: handle),
      let register: MTRegisterFunction = Self.symbol("MTRegisterContactFrameCallback", in: handle),
      let unregister: MTRegisterFunction = Self.symbol(
        "MTUnregisterContactFrameCallback", in: handle),
      let startDevice: MTDeviceStartFunction = Self.symbol("MTDeviceStart", in: handle),
      let stopDevice: MTDeviceStopFunction = Self.symbol("MTDeviceStop", in: handle)
    else { return false }

    guard let list = createList()?.takeRetainedValue(), CFArrayGetCount(list) > 0 else {
      logger.error("No multitouch device found")
      return false
    }
    let api = Api(
      unregister: unregister, stopDevice: stopDevice)
    for index in 0..<CFArrayGetCount(list) {
      guard let device = CFArrayGetValueAtIndex(list, index) else { continue }
      let pointer = UnsafeMutableRawPointer(mutating: device)
      register(pointer, contactFrameCallback)
      _ = startDevice(pointer, 0)
    }
    self.api = api
    devices = list
    candidate = .idle
    activeMonitors.append(WeakMonitor(monitor: self))
    return true
  }

  public func stop() {
    guard let api, let devices else { return }
    for index in 0..<CFArrayGetCount(devices) {
      guard let device = CFArrayGetValueAtIndex(devices, index) else { continue }
      let pointer = UnsafeMutableRawPointer(mutating: device)
      api.unregister(pointer, contactFrameCallback)
      _ = api.stopDevice(pointer)
    }
    activeMonitors.removeAll { $0.monitor == nil || $0.monitor === self }
    self.api = nil
    self.devices = nil
    candidate = .idle
  }

  fileprivate func handle(fingers: Int, x: Double, y: Double) {
    guard api != nil else { return }
    guard fingers == fingerCount else {
      if case .swiping = candidate { onSwipe?(0, .ended) }
      candidate = .idle
      return
    }
    switch candidate {
    case .idle:
      candidate = .undecided(startX: x, startY: y)
    case .undecided(let startX, let startY):
      let dx = x - startX
      let dy = y - startY
      guard (dx * dx + dy * dy).squareRoot() >= Self.decisionDistance else { return }
      if abs(dx) > Self.horizontalRatio * abs(dy) {
        candidate = .swiping(lastX: x)
        onSwipe?(dx, .began)
      } else {
        candidate = .ignored
      }
    case .swiping(let lastX):
      candidate = .swiping(lastX: x)
      onSwipe?(x - lastX, .changed)
    case .ignored:
      break
    }
  }

  private static func symbol<T>(_ name: String, in handle: UnsafeMutableRawPointer) -> T? {
    guard let address = dlsym(handle, name) else {
      logger.error("MultitouchSupport is missing \(name)")
      return nil
    }
    return unsafeBitCast(address, to: T.self)
  }
}
