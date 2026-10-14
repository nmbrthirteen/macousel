import Foundation

struct SceneTimeline {
  static let response = 0.55
  static let fade = 0.32

  let frames: [SceneFrame]
  let restingIndex: Int
  let duration: TimeInterval
  private let starts: [TimeInterval]

  init(frames: [SceneFrame], restingIndex: Int = 0) {
    precondition(frames.indices.contains(restingIndex), "A scene needs its resting frame")
    self.frames = frames
    self.restingIndex = restingIndex
    var starts = frames.reduce(into: [TimeInterval(0)]) { starts, frame in
      starts.append(starts[starts.count - 1] + frame.hold.timeInterval)
    }
    duration = starts.removeLast()
    self.starts = starts
  }

  var restingPose: ScenePose { ScenePose(frames[restingIndex]) }

  func pose(at time: TimeInterval) -> ScenePose {
    let looped = max(time, 0).truncatingRemainder(dividingBy: duration)
    var start = ScenePose(frames[0])
    var index = 0
    while index + 1 < frames.count, starts[index + 1] <= looped {
      start = segment(index, from: start, elapsed: frames[index].hold.timeInterval)
      index += 1
    }
    var pose = segment(index, from: start, elapsed: looped - starts[index])
    pose.stage = min(1, looped / Self.fade, (duration - looped) / Self.fade)
    return pose
  }

  static func eased(_ elapsed: TimeInterval) -> Double {
    let phase = 2 * .pi / response * max(elapsed, 0)
    return 1 - (1 + phase) * exp(-phase)
  }

  private func segment(_ index: Int, from start: ScenePose, elapsed: TimeInterval) -> ScenePose {
    index == 0 ? start : start.moving(toward: frames[index], by: Self.eased(elapsed))
  }
}
