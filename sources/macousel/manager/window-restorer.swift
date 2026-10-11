import CoreGraphics
import Foundation
import WindowSystem

final class WindowRestorer {
  private static let minimumReachableWidth: CGFloat = 120

  private struct SavedFrame: Codable {
    var pid: Int32
    var frame: CGRect
  }

  private struct Snapshot: Codable {
    var bootSession: String
    var frames: [CGWindowID: SavedFrame]
  }

  private static let defaultsKey = "originalFrames"

  private let defaults: UserDefaults
  private let bootSession: String
  private var originalFrames: [CGWindowID: SavedFrame]

  init(defaults: UserDefaults = .standard, bootSession: String) {
    self.defaults = defaults
    self.bootSession = bootSession
    originalFrames = Self.load(from: defaults, bootSession: bootSession)
  }

  func remember(_ window: any WindowHandle, frame: CGRect) {
    if let saved = originalFrames[window.id], saved.pid == window.pid { return }
    originalFrames[window.id] = SavedFrame(pid: window.pid, frame: frame)
    persist()
  }

  func retain(only alive: Set<CGWindowID>) {
    let retained = originalFrames.filter { alive.contains($0.key) }
    guard retained.count != originalFrames.count else { return }
    originalFrames = retained
    persist()
  }

  func forgetAll() {
    originalFrames = [:]
    persist()
  }

  private static func load(from defaults: UserDefaults, bootSession: String) -> [CGWindowID:
    SavedFrame]
  {
    guard let data = defaults.data(forKey: defaultsKey),
      let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data),
      snapshot.bootSession == bootSession
    else { return [:] }
    return snapshot.frames
  }

  private func persist() {
    let snapshot = Snapshot(bootSession: bootSession, frames: originalFrames)
    guard let data = try? JSONEncoder().encode(snapshot) else { return }
    defaults.set(data, forKey: Self.defaultsKey)
  }

  func restore(_ windows: [any WindowHandle], on displays: [Display]) {
    for window in windows {
      guard let frame = originalFrames[window.id]?.frame ?? window.frame else { continue }
      window.setFrame(reachable(frame, on: displays))
    }
  }

  func restoreSaved(_ windows: [any WindowHandle], on displays: [Display]) {
    restore(windows.filter { originalFrames[$0.id]?.pid == $0.pid }, on: displays)
  }

  private func reachable(_ frame: CGRect, on displays: [Display]) -> CGRect {
    let isReachable = displays.contains {
      $0.visibleFrame.intersection(frame).width >= min(frame.width, Self.minimumReachableWidth)
    }
    guard !isReachable,
      let nearest = displays.min(by: {
        $0.frame.squaredDistance(to: frame.center) < $1.frame.squaredDistance(to: frame.center)
      })
    else { return frame }
    return frame.clamped(into: nearest.visibleFrame)
  }
}
