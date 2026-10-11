final class DragPoller {
  static let interval = Duration.seconds(1.0 / 60)

  private let clock: any AnimationClock
  private var generation = 0

  init(clock: any AnimationClock) {
    self.clock = clock
  }

  func start(_ tick: @escaping () -> Bool) {
    generation += 1
    arm(tick, token: generation)
  }

  func stop() {
    generation += 1
  }

  private func arm(_ tick: @escaping () -> Bool, token: Int) {
    clock.schedule(after: Self.interval) { [weak self] in
      guard let self, generation == token, tick() else { return }
      arm(tick, token: token)
    }
  }
}
