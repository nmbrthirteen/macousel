import CoreGraphics
import StripCore
import SwiftUI

@Observable
final class OverviewPreviews {
  private(set) var images: [WindowID: CGImage] = [:]
  private(set) var needsPermission = false
  @ObservationIgnored private let capture: any WindowCapture
  @ObservationIgnored private var loading: Task<Void, Never>?

  init(capture: any WindowCapture) {
    self.capture = capture
  }

  static func requests(for geometry: OverviewGeometry, backingScale: Double)
    -> [WindowCaptureRequest]
  {
    geometry.cards.map { card in
      WindowCaptureRequest(
        window: card.id,
        pixelSize: CGSize(
          width: card.rect.width * backingScale, height: card.rect.height * backingScale))
    }
  }

  @discardableResult
  func load(_ requests: [WindowCaptureRequest]) -> Task<Void, Never>? {
    release()
    needsPermission = !capture.isPermitted
    guard !needsPermission, !requests.isEmpty else { return nil }
    let stream = capture.capture(requests)
    let task = Task { [weak self] in
      for await (window, image) in stream {
        guard !Task.isCancelled else { return }
        self?.reveal(image, for: window)
      }
    }
    loading = task
    return task
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
  }

  private func reveal(_ image: CGImage, for window: WindowID) {
    withAnimation(.easeOut(duration: OverlayTiming.overviewPreviewFade)) {
      images[window] = image
    }
  }
}
