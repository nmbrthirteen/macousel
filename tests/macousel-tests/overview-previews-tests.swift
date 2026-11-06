import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct OverviewPreviewsTests {
  private let requests = [
    WindowCaptureRequest(window: WindowID(1), pixelSize: CGSize(width: 200, height: 100)),
    WindowCaptureRequest(window: WindowID(2), pixelSize: CGSize(width: 300, height: 100)),
  ]
  private let desktop = DesktopCaptureRequest(
    displayFrame: CGRect(x: 0, y: 0, width: 1600, height: 1000), backingScale: 2,
    excluding: [WindowID(1), WindowID(2)])
  private let budget = Duration.seconds(5)

  @Test func picturesArriveForEveryRequestedWindow() async {
    let capture = FakeWindowCapture()
    let previews = OverviewPreviews(capture: capture)

    await previews.load(requests, budget: budget)

    #expect(Set(previews.images.keys) == [WindowID(1), WindowID(2)])
    #expect(!previews.needsPermission)
  }

  @Test func loadingWaitsForTheDesktopAndTheRealWindowFrames() async {
    let capture = FakeWindowCapture()
    let real = CGRect(x: 40, y: 30, width: 900, height: 700)
    capture.frames = [WindowID(1): real]
    let previews = OverviewPreviews(capture: capture)

    await previews.load(requests, desktop: desktop, budget: budget)

    #expect(previews.desktop != nil)
    #expect(previews.frames[WindowID(1)] == real)
    #expect(capture.desktops == [desktop])
  }

  @Test func aStalledCaptureGivesUpAtTheBudgetAndKeepsTheRest() async {
    let capture = FakeWindowCapture()
    capture.stalled = [WindowID(2)]
    let previews = OverviewPreviews(capture: capture)
    let clock = ContinuousClock()

    let started = clock.now
    await previews.load(requests, budget: .milliseconds(80))

    #expect(clock.now - started >= .milliseconds(80))
    #expect(Set(previews.images.keys) == [WindowID(1)])
    previews.release()
  }

  @Test func capturesThatFinishEarlyDoNotWaitForTheBudget() async {
    let previews = OverviewPreviews(capture: FakeWindowCapture())
    let clock = ContinuousClock()

    let started = clock.now
    await previews.load(requests, budget: .seconds(30))

    #expect(clock.now - started < .seconds(20))
  }

  @Test func releasingDropsEveryPicture() async {
    let previews = OverviewPreviews(capture: FakeWindowCapture())
    await previews.load(requests, desktop: desktop, budget: budget)

    previews.release()

    #expect(previews.images.isEmpty)
    #expect(previews.desktop == nil)
    #expect(previews.frames.isEmpty)
  }

  @Test func openingAgainCapturesAfreshInsteadOfReusingPictures() async {
    let capture = FakeWindowCapture()
    let previews = OverviewPreviews(capture: capture)
    await previews.load(requests, budget: budget)

    await previews.load(Array(requests.prefix(1)), budget: budget)

    #expect(Set(previews.images.keys) == [WindowID(1)])
    #expect(capture.captured.count == 2)
  }

  @Test func withoutPermissionNothingIsCapturedAndTheNoticeShows() async {
    let capture = FakeWindowCapture()
    capture.isPermitted = false
    let previews = OverviewPreviews(capture: capture)

    await previews.load(requests, desktop: desktop, budget: budget)

    #expect(capture.captured.isEmpty)
    #expect(previews.images.isEmpty)
    #expect(previews.desktop == nil)
    #expect(previews.needsPermission)
    #expect(capture.permissionRequests == 0)
  }

  @Test func askingForPermissionOnlyHappensOnRequest() async {
    let capture = FakeWindowCapture()
    capture.isPermitted = false
    let previews = OverviewPreviews(capture: capture)
    await previews.load(requests, budget: budget)

    previews.requestPermission()

    #expect(capture.permissionRequests == 1)
  }

  @Test func onScreenWindowsAreCapturedAtTheirFullSize() {
    let display = CGRect(x: 0, y: 0, width: 1600, height: 1000)
    let frame = CGRect(x: 100, y: 50, width: 800, height: 900)
    let geometry = OverviewGeometry(
      snapshot: snapshot(frames: [frame]), size: display.size)

    let made = OverviewPreviews.requests(for: geometry, fullSizeOn: display, backingScale: 2)

    #expect(made.map(\.pixelSize) == [CGSize(width: 1600, height: 1800)])
  }

  @Test func parkedWindowsAreCapturedAtTheirCardSize() {
    let display = CGRect(x: 0, y: 0, width: 1600, height: 1000)
    let parked = CGRect(x: 1590, y: 50, width: 800, height: 900)
    let geometry = OverviewGeometry(snapshot: snapshot(frames: [parked]), size: display.size)

    let made = OverviewPreviews.requests(for: geometry, fullSizeOn: display, backingScale: 2)

    let card = geometry.cards[0].rect
    #expect(made.map(\.pixelSize) == [CGSize(width: card.width * 2, height: card.height * 2)])
    #expect(made[0].pixelSize.width < 800 * 2)
  }

  @Test func withoutTheFlightEveryWindowIsCapturedAtItsCardSize() {
    let frame = CGRect(x: 100, y: 50, width: 800, height: 900)
    let geometry = OverviewGeometry(
      snapshot: snapshot(frames: [frame]), size: CGSize(width: 1600, height: 1000))

    let made = OverviewPreviews.requests(for: geometry, fullSizeOn: nil, backingScale: 2)

    let card = geometry.cards[0].rect
    #expect(made.map(\.pixelSize) == [CGSize(width: card.width * 2, height: card.height * 2)])
  }

  private func snapshot(frames: [CGRect]) -> OverviewSnapshot {
    OverviewSnapshot(
      columns: frames.enumerated().map { index, frame in
        OverviewSnapshot.Column(
          width: frame.width,
          cards: [
            OverviewSnapshot.Card(
              window: WindowID(UInt32(index + 1)), title: "One", bundleIdentifier: nil,
              heightShare: 1, frame: frame)
          ])
      }, stripHeight: 900, selection: nil)
  }
}
