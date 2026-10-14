import Observation
@Observable
final class OnboardingFlow {
  enum Step: Int, CaseIterable {
    case howItWorks, accessibility, shortcuts, menuBar
  }

  private(set) var step = Step.howItWorks
  @ObservationIgnored private let onFinish: () -> Void

  init(onFinish: @escaping () -> Void) {
    self.onFinish = onFinish
  }

  var canGoBack: Bool { step != Step.allCases.first }
  var isLastStep: Bool { step == Step.allCases.last }

  var continueTitle: String {
    isLastStep ? "Get started" : "Continue"
  }

  func goBack() {
    guard let previous = Step(rawValue: step.rawValue - 1) else { return }
    step = previous
  }

  func advance() {
    guard let next = Step(rawValue: step.rawValue + 1) else {
      onFinish()
      return
    }
    step = next
  }
}
