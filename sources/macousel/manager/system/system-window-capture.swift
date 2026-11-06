import AppKit
import ScreenCaptureKit
import StripCore

struct SystemWindowCapture: WindowCapture {
  // SCContentFilter and SCStreamConfiguration are not marked Sendable, but each job is built
  // once, never mutated afterwards, and only read by the one capture call that receives it.
  private nonisolated struct Job: @unchecked Sendable {
    let window: WindowID
    let filter: SCContentFilter
    let configuration: SCStreamConfiguration
  }

  var isPermitted: Bool { CGPreflightScreenCaptureAccess() }

  func requestPermission() {
    CGRequestScreenCaptureAccess()
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
    else { return }
    NSWorkspace.shared.open(url)
  }

  func capture(_ requests: [WindowCaptureRequest]) -> AsyncStream<(WindowID, CGImage)> {
    AsyncStream { continuation in
      let task = Task {
        await Self.capture(requests, into: continuation)
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  @concurrent
  private static func capture(
    _ requests: [WindowCaptureRequest],
    into continuation: AsyncStream<(WindowID, CGImage)>.Continuation
  ) async {
    guard
      let content = try? await SCShareableContent.excludingDesktopWindows(
        false, onScreenWindowsOnly: false)
    else { return }
    let windows = Dictionary(
      content.windows.map { ($0.windowID, $0) }, uniquingKeysWith: { first, _ in first })
    let jobs = requests.compactMap { request in
      windows[request.window.rawValue].map { window in
        Job(
          window: request.window, filter: SCContentFilter(desktopIndependentWindow: window),
          configuration: configuration(for: request))
      }
    }
    await withTaskGroup(of: Void.self) { group in
      for job in jobs {
        group.addTask {
          guard !Task.isCancelled,
            let image = try? await SCScreenshotManager.captureImage(
              contentFilter: job.filter, configuration: job.configuration)
          else { return }
          continuation.yield((job.window, image))
        }
      }
    }
  }

  private nonisolated static func configuration(for request: WindowCaptureRequest)
    -> SCStreamConfiguration
  {
    let configuration = SCStreamConfiguration()
    configuration.width = max(Int(request.pixelSize.width.rounded(.up)), 1)
    configuration.height = max(Int(request.pixelSize.height.rounded(.up)), 1)
    configuration.showsCursor = false
    configuration.ignoreShadowsSingleWindow = true
    return configuration
  }
}
