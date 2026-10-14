import SwiftUI

struct AboutPane: View {
  private static let repositoryURL = URL(string: "https://github.com/nmbrthirteen/macousel")!
  private static let makerURL = URL(string: "https://nikusha.com")!

  let updater: Updater
  let diagnostics: DiagnosticsAction
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
            .font(.title2.bold())
          Text(info.version)
            .foregroundStyle(.secondary)
          Text("A scrolling window manager for macOS.")
            .multilineTextAlignment(.center)
          credits
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metrics.Spacing.comfortable)
      }

      UpdateSection(updater: updater)

      SettingsGroup(title: "Licenses") {
        CaptionText("Window management by Paneru, used under the MIT license.")
        Button("Show licenses") { LicenseFolder.open() }
      }

      SettingsGroup(title: "Help") {
        Button("Show welcome guide", action: onShowWelcome)
        ReportProblemRow(diagnostics: diagnostics)
      }
    }
  }

  private var credits: some View {
    VStack(spacing: Metrics.Spacing.tight) {
      Text("Made by Nika Siradze")
        .foregroundStyle(.secondary)
      HStack(spacing: Metrics.Spacing.comfortable) {
        Link("nikusha.com", destination: Self.makerURL)
        Text("·").foregroundStyle(.tertiary)
        Link("Source on GitHub", destination: Self.repositoryURL)
      }
    }
    .font(.callout)
    .padding(.top, Metrics.Spacing.regular)
  }
}
