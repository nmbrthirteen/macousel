import AppKit
import SwiftUI

struct WindowButtonDimming: NSViewRepresentable {
  let buttons: [NSWindow.ButtonType]

  func makeNSView(context: Context) -> WindowButtonDimmingView {
    WindowButtonDimmingView(buttons: buttons)
  }

  func updateNSView(_ view: WindowButtonDimmingView, context: Context) {}
}

final class WindowButtonDimmingView: NSView {
  private let buttons: [NSWindow.ButtonType]

  init(buttons: [NSWindow.ButtonType]) {
    self.buttons = buttons
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    for button in buttons {
      window?.standardWindowButton(button)?.isEnabled = false
    }
  }
}

extension View {
  func dimsWindowButtons(_ buttons: NSWindow.ButtonType...) -> some View {
    background(WindowButtonDimming(buttons: buttons))
  }
}
