import Darwin

// If Macousel crashes, Paneru would keep tiling with no menu bar icon to stop it. Macousel
// starts this small copy of itself beside the engine. It waits on both processes in a kqueue
// and stops the engine once Macousel is gone, then exits.
nonisolated enum EngineWatchdog {
  static let command = "watch-engine"
  private static let grace = 5

  static func arguments(parent: pid_t, engine: pid_t) -> [String] {
    [command, String(parent), String(engine)]
  }

  static func run(arguments: [String]) -> Int32? {
    guard arguments.count == 3, arguments[0] == command,
      let parent = pid_t(arguments[1]), let engine = pid_t(arguments[2])
    else { return nil }
    let queue = kqueue()
    guard queue >= 0 else { return 1 }
    defer { close(queue) }
    // Once registered, the engine's exit is queued even if it happens before we wait, so a
    // signal never reaches a pid the engine no longer holds.
    guard watch(engine, on: queue) else { return 0 }
    guard watch(parent, on: queue) else {
      stop(engine, on: queue)
      return 0
    }
    while true {
      var event = kevent()
      let count = kevent(queue, nil, 0, &event, 1, nil)
      if count < 0 && errno == EINTR { continue }
      guard count == 1 else { return 1 }
      if pid_t(event.ident) != engine { stop(engine, on: queue) }
      return 0
    }
  }

  private static func watch(_ pid: pid_t, on queue: Int32) -> Bool {
    var change = kevent(
      ident: UInt(pid), filter: Int16(EVFILT_PROC), flags: UInt16(EV_ADD | EV_ONESHOT),
      fflags: UInt32(NOTE_EXIT), data: 0, udata: nil)
    return kevent(queue, &change, 1, nil, 0, nil) == 0
  }

  private static func stop(_ engine: pid_t, on queue: Int32) {
    kill(engine, SIGTERM)
    var timeout = timespec(tv_sec: grace, tv_nsec: 0)
    var event = kevent()
    if kevent(queue, nil, 0, &event, 1, &timeout) == 1, pid_t(event.ident) == engine { return }
    kill(engine, SIGKILL)
  }
}
