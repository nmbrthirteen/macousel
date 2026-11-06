import AppKit
import ScreenCaptureKit
import StripCore

struct SystemWindowCapture: WindowCapture {
  private nonisolated enum Subject: Sendable {
    case window(WindowID, frame: CGRect)
    case desktop
  }

  // SCContentFilter and SCStreamConfiguration are not marked Sendable, but each job is built
  // once, never mutated afterwards, and only read by the one capture call that receives it.
  private nonisolated struct Job: @unchecked Sendable {
    let subject: Subject
    let filter: SCContentFilter
    let configuration: SCStreamConfiguration

    func picture(_ image: CGImage) -> WindowCapturePicture {
      switch subject {
      case .window(let window, let frame): .window(window, image, frame: frame)
      case .desktop: .desktop(image)
      }
    }
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

  func capture(_ requests: [WindowCaptureRequest], desktop: DesktopCaptureRequest?)
    -> AsyncStream<WindowCapturePicture>
  {
    AsyncStream { continuation in
      let task = Task {
        await Self.capture(requests, desktop: desktop, into: continuation)
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  @concurrent
  private static func capture(
    _ requests: [WindowCaptureRequest], desktop: DesktopCaptureRequest?,
    into continuation: AsyncStream<WindowCapturePicture>.Continuation
  ) async {
    // Parked windows sit off the display edge but stay ordered in, so they are still listed.
    // Listing only those cuts the lookup from about 50 ms to about 20 ms.
    guard
      let content = try? await SCShareableContent.excludingDesktopWindows(
        false, onScreenWindowsOnly: true)
    else { return }
    let windows = Dictionary(
      content.windows.map { ($0.windowID, $0) }, uniquingKeysWith: { first, _ in first })
    var jobs = requests.compactMap { request in
      windows[request.window.rawValue].map { window in
        Job(
          subject: .window(request.window, frame: window.frame),
          filter: SCContentFilter(desktopIndependentWindow: window),
          configuration: configuration(pixelSize: request.pixelSize))
      }
    }
    if let desktop, let job = desktopJob(for: desktop, in: content) { jobs.append(job) }
    await withTaskGroup(of: Void.self) { group in
      for job in jobs {
        group.addTask {
          guard !Task.isCancelled,
            let image = try? await SCScreenshotManager.captureImage(
              contentFilter: job.filter, configuration: job.configuration)
          else { return }
          continuation.yield(job.picture(image))
        }
      }
    }
  }

  // Leaves out this app's own panels too, so a focus border or dim layer never ends up baked
  // into the picture that stands in for the desktop.
  private nonisolated static func desktopJob(
    for request: DesktopCaptureRequest, in content: SCShareableContent
  ) -> Job? {
    let center = CGPoint(x: request.displayFrame.midX, y: request.displayFrame.midY)
    guard
      let display = content.displays.first(where: { $0.frame == request.displayFrame })
        ?? content.displays.first(where: { $0.frame.contains(center) })
    else { return nil }
    let excluded = Set(request.excluding.map(\.rawValue))
    let ownProcess = ProcessInfo.processInfo.processIdentifier
    let hidden = content.windows.filter {
      excluded.contains($0.windowID) || $0.owningApplication?.processID == ownProcess
    }
    let size = display.frame.size
    return Job(
      subject: .desktop, filter: SCContentFilter(display: display, excludingWindows: hidden),
      configuration: configuration(
        pixelSize: CGSize(
          width: size.width * request.backingScale, height: size.height * request.backingScale)))
  }

  private nonisolated static func configuration(pixelSize: CGSize) -> SCStreamConfiguration {
    let configuration = SCStreamConfiguration()
    configuration.width = max(Int(pixelSize.width.rounded(.up)), 1)
    configuration.height = max(Int(pixelSize.height.rounded(.up)), 1)
    configuration.showsCursor = false
    configuration.ignoreShadowsSingleWindow = true
    return configuration
  }
}
