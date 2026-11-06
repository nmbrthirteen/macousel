import AppKit
import SwiftUI

// Opens once at launch to hand the window opener to AppKit, then closes. The window turns
// transparent before its first display, so it never shows.
struct SettingsOpenerCapture: View {
  let settings: SettingsWindowController
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow

  var body: some View {
    Color.clear
      .frame(width: 0, height: 0)
      .background(InvisibleWindow())
      .onAppear {
        settings.capture(openWindow)
        // Dismissing during onAppear is ignored because the scene is not registered yet.
        DispatchQueue.main.async { dismissWindow(id: SettingsWindowController.openerWindowID) }
      }
  }
}

private struct InvisibleWindow: NSViewRepresentable {
  func makeNSView(context: Context) -> InvisibleWindowView {
    InvisibleWindowView()
  }

  func updateNSView(_ view: InvisibleWindowView, context: Context) {}
}

private final class InvisibleWindowView: NSView {
  override func viewWillMove(toWindow window: NSWindow?) {
    super.viewWillMove(toWindow: window)
    window?.alphaValue = 0
    window?.ignoresMouseEvents = true
    window?.isExcludedFromWindowsMenu = true
    window?.collectionBehavior.formUnion([.transient, .ignoresCycle])
  }

  // SwiftUI sometimes keeps the dismissed window ordered in, so it is taken off screen here too.
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    guard let window else { return }
    DispatchQueue.main.async { window.orderOut(nil) }
  }
}
