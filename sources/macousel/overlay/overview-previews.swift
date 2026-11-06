import CoreGraphics
import StripCore
import SwiftUI

@Observable
final class OverviewPreviews {
  private(set) var images: [WindowID: CGImage] = [:]
  private(set) var needsPermission = false
  @ObservationIgnored private(set) var desktop: CGImage?
  @ObservationIgnored private(set) var frames: [WindowID: CGRect] = [:]
  @ObservationIgnored private let capture: any WindowCapture
  @ObservationIgnored private var loading: Task<Void, Never>?
  @ObservationIgnored private var isRevealed = false

  init(capture: any WindowCapture) {
    self.capture = capture
  }

  // A window on screen is captured at its full size, so its picture can stand exactly where the
  // window is. A parked window only ever shows at its card size, so that is all it costs.
  static func requests(
    for geometry: OverviewGeometry, fullSizeOn displayFrame: CGRect?, backingScale: Double
  ) -> [WindowCaptureRequest] {
    geometry.everyCard.map { card in
      let shown = displayFrame.flatMap { displayFrame in
        card.content.frame.flatMap { OverviewFlight.isShown($0, on: displayFrame) ? $0 : nil }
      }
      let size = shown?.size ?? card.rect.size
      return WindowCaptureRequest(
        window: card.id,
        pixelSize: CGSize(width: size.width * backingScale, height: size.height * backingScale))
    }
  }

  // Waits until every picture is in or the budget runs out. Pictures that miss the budget still
  // fade in over their icon cards; a late desktop picture is dropped, since the backdrop it
  // belongs under is already showing.
  func load(
    _ requests: [WindowCaptureRequest], desktop request: DesktopCaptureRequest? = nil,
    budget: Duration
  ) async {
    release()
    needsPermission = !capture.isPermitted
    guard !needsPermission, !requests.isEmpty || request != nil else {
      isRevealed = true
      return
    }
    let stream = capture.capture(requests, desktop: request)
    let (settled, settle) = AsyncStream<Never>.makeStream()
    loading = Task { [weak self] in
      for await picture in stream {
        guard !Task.isCancelled else { break }
        self?.keep(picture)
      }
      settle.finish()
    }
    await withTaskGroup(of: Void.self) { group in
      group.addTask { for await _ in settled {} }
      group.addTask { try? await Task.sleep(for: budget) }
      await group.next()
      group.cancelAll()
    }
    isRevealed = true
  }

  func requestPermission() {
    capture.requestPermission()
  }

  func stopLoading() {
    loading?.cancel()
    loading = nil
  }

  func release() {
    stopLoading()
    images = [:]
    desktop = nil
    frames = [:]
    isRevealed = false
  }

  private func keep(_ picture: WindowCapturePicture) {
    switch picture {
    case .window(let window, let image, let frame):
      guard isRevealed else {
        frames[window] = frame
        images[window] = image
        return
      }
      withAnimation(.easeOut(duration: OverlayTiming.overviewPreviewFade)) {
        images[window] = image
      }
    case .desktop(let image):
      if !isRevealed { desktop = image }
    }
  }
}
