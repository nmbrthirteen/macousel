import ApplicationServices
import Foundation

nonisolated struct WindowServerFocus: Sendable {
  private static let userGeneratedMode: UInt32 = 0x200
  private static let noWindowsMode: UInt32 = 0x400
  private static let focusChangeKind: UInt8 = 0x0d
  private static let focusChangeFlagOffset = 0x8a
  private static let deactivateFlag: UInt8 = 0x02
  private static let activateFlag: UInt8 = 0x01
  private static let focusChangeSettleMicroseconds: UInt32 = 10_000
  private static let eventRecordLength = 0xf8
  private static let lengthOffset = 0x04
  private static let phaseOffset = 0x08
  private static let targetMaskOffset = 0x20
  private static let targetMaskLength = 0x10
  private static let kindOffset = 0x3a
  private static let windowOffset = 0x3c
  private static let keyWindowKind: UInt8 = 0x10
  private static let pressPhase: UInt8 = 0x01
  private static let releasePhase: UInt8 = 0x02

  static let shared = WindowServerFocus()

  private let processForPID: GetProcessForPIDFunction?
  private let setFrontProcess: SetFrontProcessWithOptionsFunction?
  private let postEventRecord: PostEventRecordFunction?

  private init() {
    let skyLight = dlopen(skyLightFrameworkPath, RTLD_LAZY)
    let applicationServices = dlopen(applicationServicesFrameworkPath, RTLD_LAZY)
    processForPID = dlsym(applicationServices, "GetProcessForPID").map {
      unsafeBitCast($0, to: GetProcessForPIDFunction.self)
    }
    setFrontProcess = dlsym(skyLight, "_SLPSSetFrontProcessWithOptions").map {
      unsafeBitCast($0, to: SetFrontProcessWithOptionsFunction.self)
    }
    postEventRecord = dlsym(skyLight, "SLPSPostEventRecordTo").map {
      unsafeBitCast($0, to: PostEventRecordFunction.self)
    }
  }

  var isAvailable: Bool {
    processForPID != nil && setFrontProcess != nil && postEventRecord != nil
  }

  func bringToFront(_ window: CGWindowID, of pid: pid_t) -> Bool {
    guard let processForPID, let setFrontProcess, let postEventRecord else { return false }
    var process = ProcessSerialNumber()
    guard processForPID(pid, &process) == noErr,
      setFrontProcess(&process, window, Self.userGeneratedMode) == .success
    else { return false }
    return [Self.pressPhase, Self.releasePhase].allSatisfy { phase in
      var record = keyWindowRecord(for: window, phase: phase)
      return postEventRecord(&process, &record) == .success
    }
  }

  func focusWithoutRaising(
    _ window: CGWindowID, of pid: pid_t, replacing current: (window: CGWindowID, pid: pid_t)?
  ) -> Bool {
    guard let processForPID, let setFrontProcess, let postEventRecord else { return false }
    var process = ProcessSerialNumber()
    guard processForPID(pid, &process) == noErr else { return false }
    if let current, current.pid == pid {
      var record = focusChangeRecord(for: current.window, flag: Self.deactivateFlag)
      guard postEventRecord(&process, &record) == .success else { return false }
      usleep(Self.focusChangeSettleMicroseconds)
      record = focusChangeRecord(for: window, flag: Self.activateFlag)
      guard postEventRecord(&process, &record) == .success else { return false }
    }
    guard setFrontProcess(&process, window, Self.noWindowsMode) == .success else { return false }
    return [Self.pressPhase, Self.releasePhase].allSatisfy { phase in
      var record = keyWindowRecord(for: window, phase: phase)
      return postEventRecord(&process, &record) == .success
    }
  }

  private func focusChangeRecord(for window: CGWindowID, flag: UInt8) -> [UInt8] {
    var record = [UInt8](repeating: 0, count: Self.eventRecordLength)
    record[Self.lengthOffset] = UInt8(Self.eventRecordLength)
    record[Self.phaseOffset] = Self.focusChangeKind
    record[Self.focusChangeFlagOffset] = flag
    write(window, into: &record)
    return record
  }

  private func keyWindowRecord(for window: CGWindowID, phase: UInt8) -> [UInt8] {
    var record = [UInt8](repeating: 0, count: Self.eventRecordLength)
    record[Self.lengthOffset] = UInt8(Self.eventRecordLength)
    record[Self.phaseOffset] = phase
    record[Self.kindOffset] = Self.keyWindowKind
    for offset in 0..<Self.targetMaskLength {
      record[Self.targetMaskOffset + offset] = 0xff
    }
    write(window, into: &record)
    return record
  }

  private func write(_ window: CGWindowID, into record: inout [UInt8]) {
    withUnsafeBytes(of: window.littleEndian) { bytes in
      for (offset, byte) in bytes.enumerated() {
        record[Self.windowOffset + offset] = byte
      }
    }
  }
}
