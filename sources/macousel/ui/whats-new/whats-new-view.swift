import AppKit
import SwiftUI

struct WhatsNewView: View {
  private static let iconSide = 64.0
  private static let symbolWidth = 20.0

  let notes: ReleaseNotes
  let onDone: () -> Void
  @State private var accessibility = AccessibilityStatus()

  var body: some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.roomy) {
      HStack(spacing: Metrics.Spacing.comfortable) {
        Image(nsImage: NSApp.applicationIconImage)
          .resizable()
          .frame(width: Self.iconSide, height: Self.iconSide)
          .accessibilityHidden(true)
        Text("Macousel \(notes.version)")
          .font(.title.weight(.semibold))
      }
      ScrollView {
        VStack(alignment: .leading, spacing: Metrics.Spacing.comfortable) {
          ForEach(notes.blocks.indices, id: \.self) { index in
            block(notes.blocks[index])
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .scrollBounceBehavior(.basedOnSize)
      if !accessibility.isGranted {
        VStack(alignment: .leading, spacing: Metrics.Spacing.tight) {
          AccessibilityGrantLine(status: accessibility)
          CaptionText("Turn Macousel on in System Settings > Privacy & Security > Accessibility.")
        }
      }
      HStack {
        Spacer()
        Button("Continue", action: onDone)
          .buttonStyle(.borderedProminent)
          .keyboardShortcut(.defaultAction)
      }
    }
    .padding(OnboardingMetrics.contentInset)
    .frame(width: WhatsNewMetrics.width, height: WhatsNewMetrics.height)
    .onExitCommand(perform: onDone)
    .pollsAccessibility(accessibility)
  }

  @ViewBuilder
  private func block(_ block: ReleaseNotes.Block) -> some View {
    switch block {
    case .paragraph(let text):
      Text(Self.inline(text))
        .fixedSize(horizontal: false, vertical: true)
    case .bullet(let text):
      Label {
        Text(Self.inline(text))
          .fixedSize(horizontal: false, vertical: true)
      } icon: {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.tint)
          .frame(width: Self.symbolWidth)
      }
    }
  }

  private static func inline(_ text: String) -> AttributedString {
    (try? AttributedString(
      markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
      ?? AttributedString(text)
  }
}

enum WhatsNewMetrics {
  static let width = 460.0
  static let height = 420.0
}
