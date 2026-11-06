import AppKit
import SwiftUI

struct WindowVisibilityReader: NSViewRepresentable {
  @Binding var isVisible: Bool

  func makeNSView(context: Context) -> WindowVisibilityView {
    WindowVisibilityView { isVisible = $0 }
  }

  func updateNSView(_ view: WindowVisibilityView, context: Context) {}
}

final class WindowVisibilityView: NSView {
  private let onChange: (Bool) -> Void
  private var observer: (any NSObjectProtocol)?

  init(onChange: @escaping (Bool) -> Void) {
    self.onChange = onChange
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  // Occlusion covers a minimized window, another Space, and a window fully behind others,
  // none of which change the key state on their own.
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if let observer { NotificationCenter.default.removeObserver(observer) }
    observer = nil
    guard let window else { return }
    observer = NotificationCenter.default.addObserver(
      forName: NSWindow.didChangeOcclusionStateNotification, object: window, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        guard let self, let window = self.window else { return }
        self.onChange(window.occlusionState.contains(.visible))
      }
    }
  }
}

extension View {
  func readsWindowVisibility(_ isVisible: Binding<Bool>) -> some View {
    background(WindowVisibilityReader(isVisible: isVisible))
  }
}
