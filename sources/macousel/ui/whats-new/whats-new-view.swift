import AppKit
import SwiftUI

struct WhatsNewView: View {
  private static let iconSide = 64.0
  private static let bulletWidth = 12.0

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
        VStack(alignment: .leading, spacing: Metrics.Spacing.hairline) {
          Text("What's new")
            .font(.title.weight(.semibold))
          Text("Macousel \(notes.version)")
            .foregroundStyle(.secondary)
        }
      }
      ScrollView {
        VStack(alignment: .leading, spacing: Metrics.Spacing.regular) {
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
          .buttonStyle(ContinueButtonStyle())
          .keyboardShortcut(.defaultAction)
      }
    }
    .padding(OnboardingMetrics.contentInset)
    .padding(.top, Metrics.Spacing.roomy)
    .frame(width: WhatsNewMetrics.width, height: WhatsNewMetrics.height)
    .pollsAccessibility(accessibility)
  }

  @ViewBuilder
  private func block(_ block: ReleaseNotes.Block) -> some View {
    switch block {
    case .paragraph(let text):
      Text(Self.inline(text))
        .fixedSize(horizontal: false, vertical: true)
    case .bullet(let text):
      HStack(alignment: .firstTextBaseline, spacing: Metrics.Spacing.regular) {
        Text("•").frame(width: Self.bulletWidth)
        Text(Self.inline(text))
          .fixedSize(horizontal: false, vertical: true)
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
  static let height = 460.0
}
