import CoreFoundation
import Foundation

nonisolated final class TapThreadHandle: @unchecked Sendable {
  private let lock = NSLock()
  private var runLoop: CFRunLoop?
  private let started = DispatchSemaphore(value: 0)
  private let finished = DispatchSemaphore(value: 0)

  func publish(runLoop: CFRunLoop?) {
    lock.withLock { self.runLoop = runLoop }
    started.signal()
  }

  func awaitStart() -> Bool {
    started.wait()
    return lock.withLock { runLoop != nil }
  }

  func finish() {
    finished.signal()
  }

  func stopAndWait() {
    guard let runLoop = lock.withLock({ runLoop }) else { return }
    CFRunLoopPerformBlock(runLoop, CFRunLoopMode.commonModes.rawValue) {
      CFRunLoopStop(CFRunLoopGetCurrent())
    }
    CFRunLoopWakeUp(runLoop)
    finished.wait()
  }
}
