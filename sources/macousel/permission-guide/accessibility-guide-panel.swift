import AppKit
import SwiftUI

// A utility panel that sits beside System Settings while someone switches Macousel on. It never
// takes focus from System Settings, and it follows the window if it moves.
final class AccessibilityGuidePanel {
  private static let followInterval = Duration.milliseconds(250)
  private static let gap: CGFloat = 12

  private var panel: NSPanel?
  private var follow: Task<Void, Never>?

  func show() {
    let panel = panel ?? makePanel()
    self.panel = panel
    follow?.cancel()
    follow = Task { [weak self] in
      while !Task.isCancelled {
        self?.place(panel)
        try? await Task.sleep(for: Self.followInterval)
      }
    }
  }

  func hide() {
    follow?.cancel()
    follow = nil
    panel?.orderOut(nil)
    panel?.contentView = nil
    panel = nil
  }

  // Hidden until System Settings has a window, so it never floats alone on the desktop.
  private func place(_ panel: NSPanel) {
    guard let window = SystemSettingsWindow.frame,
      let screen = NSScreen.screens.first(where: { $0.frame.intersects(window) })
    else {
      panel.orderOut(nil)
      return
    }
    let origin = GuidePanelPlacement.origin(
      for: panel.frame.size, beside: window, within: screen.visibleFrame, gap: Self.gap)
    if panel.frame.origin != origin { panel.setFrameOrigin(origin) }
    if !panel.isVisible { panel.orderFrontRegardless() }
  }

  private func makePanel() -> NSPanel {
    let panel = NSPanel(
      contentRect: .zero,
      styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel],
      backing: .buffered, defer: true)
    panel.title = "Allow Macousel"
    panel.isFloatingPanel = true
    panel.hidesOnDeactivate = false
    panel.becomesKeyOnlyIfNeeded = true
    panel.isReleasedWhenClosed = false
    panel.collectionBehavior = [.fullScreenAuxiliary, .transient, .ignoresCycle]
    let content = NSHostingView(rootView: AccessibilityGuideView())
    content.sizingOptions = [.preferredContentSize]
    panel.contentView = content
    panel.setContentSize(content.fittingSize)
    return panel
  }
}

private struct AccessibilityGuideView: View {
  var body: some View {
    HStack(alignment: .top, spacing: Metrics.Spacing.comfortable) {
      Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
        .resizable()
        .frame(width: Metrics.Size.guideIcon, height: Metrics.Size.guideIcon)
        .onDrag { NSItemProvider(object: Bundle.main.bundleURL as NSURL) }
        .accessibilityLabel("Macousel")
        .accessibilityHint("Drag into the Accessibility list in System Settings")
      VStack(alignment: .leading, spacing: Metrics.Spacing.tight) {
        Text("Switch on Macousel")
          .font(.headline)
        Text("If Macousel is not in the list, drag its icon into the list.")
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(Metrics.Spacing.roomy)
    .frame(width: Metrics.Size.guidePanelWidth, alignment: .leading)
  }
}
