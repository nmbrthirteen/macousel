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

  @Test func picturesArriveForEveryRequestedWindow() async {
    let capture = FakeWindowCapture()
    let previews = OverviewPreviews(capture: capture)

    await previews.load(requests)?.value

    #expect(Set(previews.images.keys) == [WindowID(1), WindowID(2)])
    #expect(!previews.needsPermission)
  }

  @Test func releasingDropsEveryPicture() async {
    let previews = OverviewPreviews(capture: FakeWindowCapture())
    await previews.load(requests)?.value

    previews.release()

    #expect(previews.images.isEmpty)
  }

  @Test func openingAgainCapturesAfreshInsteadOfReusingPictures() async {
    let capture = FakeWindowCapture()
    let previews = OverviewPreviews(capture: capture)
    await previews.load(requests)?.value

    await previews.load(Array(requests.prefix(1)))?.value

    #expect(Set(previews.images.keys) == [WindowID(1)])
    #expect(capture.captured.count == 2)
  }

  @Test func withoutPermissionNothingIsCapturedAndTheNoticeShows() {
    let capture = FakeWindowCapture()
    capture.isPermitted = false
    let previews = OverviewPreviews(capture: capture)

    let loading = previews.load(requests)

    #expect(loading == nil)
    #expect(capture.captured.isEmpty)
    #expect(previews.needsPermission)
    #expect(capture.permissionRequests == 0)
  }

  @Test func askingForPermissionOnlyHappensOnRequest() {
    let capture = FakeWindowCapture()
    capture.isPermitted = false
    let previews = OverviewPreviews(capture: capture)
    previews.load(requests)

    previews.requestPermission()

    #expect(capture.permissionRequests == 1)
  }

  @Test func requestsAskForTheCardSizeInPixels() {
    let snapshot = OverviewSnapshot(
      columns: [
        OverviewSnapshot.Column(
          width: 800,
          cards: [
            OverviewSnapshot.Card(
              window: WindowID(1), title: "One", bundleIdentifier: nil, heightShare: 1)
          ])
      ], stripHeight: 600, selection: nil)
    let geometry = OverviewGeometry(snapshot: snapshot, size: CGSize(width: 1600, height: 1000))

    let made = OverviewPreviews.requests(for: geometry, backingScale: 2)

    let card = geometry.cards[0].rect
    #expect(
      made == [
        WindowCaptureRequest(
          window: WindowID(1), pixelSize: CGSize(width: card.width * 2, height: card.height * 2))
      ])
    #expect(made[0].pixelSize.width < 800 * 2)
  }
}
