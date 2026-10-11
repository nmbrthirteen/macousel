import SwiftUI

struct AboutPane: View {
  let onShowWelcome: () -> Void
  private let info = AppInfo()

  var body: some View {
    SettingsForm {
      Section {
        VStack(spacing: Metrics.Spacing.regular) {
          Image(nsImage: info.icon)
            .resizable()
            .scaledToFit()
            .frame(width: Metrics.Size.aboutIcon, height: Metrics.Size.aboutIcon)
            .accessibilityHidden(true)
          Text(info.name)
            .font(.title.bold())
          Text(info.version)
            .foregroundStyle(.secondary)
          Text(
            "A scrolling window manager for macOS. Windows sit side by side on one strip, and the strip scrolls."
          )
          .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metrics.Spacing.comfortable)
      }

      Section {
        Button("Show welcome guide", action: onShowWelcome)
      }
    }
  }
}
