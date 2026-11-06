import CoreGraphics
import Foundation
import Testing

@testable import Macousel

@MainActor
private final class GuideProbe {
  var granted = false
  var grantedElsewhere = false
  var events: [String] = []
  var trust: (() -> Void)?

  lazy var guide = AccessibilityGuide(
    dependencies: .init(
      isGranted: { [unowned self] in granted },
      wasGrantedToAnotherBuild: { [unowned self] in grantedElsewhere },
      openSettings: { [unowned self] in events.append("open") },
      resetGrant: { [unowned self] in
        events.append("reset")
        grantedElsewhere = false
        return true
      },
      showHelper: { [unowned self] in events.append("show") },
      hideHelper: { [unowned self] in events.append("hide") },
      bringToFront: { [unowned self] in events.append("front") },
      watchTrust: { [unowned self] in trust = $0 },
      sleep: { _ in try await Task.sleep(for: .seconds(3600)) }))
}

@MainActor
struct AccessibilityGuideTests {
  @Test func beginningOpensTheRightPaneAndTheHelper() {
    let probe = GuideProbe()

    probe.guide.begin()

    #expect(probe.guide.phase == .guiding)
    #expect(probe.events == ["open", "show"])
  }

  @Test func theGrantFinishesTheGuideOnItsOwn() {
    let probe = GuideProbe()
    var finished = 0
    probe.guide.onGranted = { finished += 1 }
    probe.guide.begin()

    probe.granted = true
    probe.trust?()

    #expect(probe.guide.phase == .granted)
    #expect(probe.events == ["open", "show", "hide", "front"])
    #expect(finished == 1)
    #expect(probe.trust == nil)
  }

  @Test func aGrantFromAnotherBuildAsksToFixItFirst() async {
    let probe = GuideProbe()
    probe.grantedElsewhere = true

    probe.guide.begin()
    #expect(probe.guide.phase == .staleGrant)
    #expect(probe.events.isEmpty)

    await probe.guide.fixStaleGrant()
    #expect(probe.guide.phase == .guiding)
    #expect(probe.events == ["reset", "open", "show"])
  }

  @Test func anAppThatIsAlreadyTrustedFinishesWithoutOpeningAnything() {
    let probe = GuideProbe()
    probe.granted = true

    probe.guide.begin()

    #expect(probe.guide.phase == .granted)
    #expect(probe.events == ["hide"])
  }

  @Test func cancellingHidesTheHelperAndStopsWatching() {
    let probe = GuideProbe()
    probe.guide.begin()

    probe.guide.cancel()

    #expect(probe.guide.phase == .idle)
    #expect(probe.events.last == "hide")
    #expect(probe.trust == nil)
  }
}

struct GuidePanelPlacementTests {
  private let screen = CGRect(x: 0, y: 0, width: 1920, height: 1050)
  private let panel = CGSize(width: 320, height: 100)

  @Test func sitsBesideTheWindowWhenThereIsRoom() {
    let window = CGRect(x: 200, y: 300, width: 700, height: 600)

    let origin = GuidePanelPlacement.origin(for: panel, beside: window, within: screen, gap: 12)

    #expect(origin == CGPoint(x: 912, y: 800))
  }

  @Test func movesToTheLeadingSideWhenTheTrailingSideIsFull() {
    let window = CGRect(x: 1300, y: 300, width: 600, height: 600)

    let origin = GuidePanelPlacement.origin(for: panel, beside: window, within: screen, gap: 12)

    #expect(origin == CGPoint(x: 968, y: 800))
  }

  @Test func fallsBackInsideTheScreenWhenNothingFits() {
    let window = CGRect(x: 0, y: 0, width: 1920, height: 1050)

    let origin = GuidePanelPlacement.origin(for: panel, beside: window, within: screen, gap: 12)

    #expect(screen.contains(CGRect(origin: origin, size: panel)))
  }
}

@MainActor
struct AccessibilityGrantHistoryTests {
  @Test func aGrantRecordedByAnotherBuildIsReported() throws {
    let defaults = try #require(UserDefaults(suiteName: "grant-history-\(UUID().uuidString)"))
    AccessibilityGrantHistory(defaults: defaults, build: "10").recordGranted()

    let current = AccessibilityGrantHistory(defaults: defaults, build: "11")

    #expect(current.wasGrantedToAnotherBuild(isGranted: false))
    #expect(!current.wasGrantedToAnotherBuild(isGranted: true))
    #expect(!AccessibilityGrantHistory(defaults: defaults, build: "10")
      .wasGrantedToAnotherBuild(isGranted: false))
  }
}
