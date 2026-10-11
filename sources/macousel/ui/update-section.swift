import SwiftUI

struct UpdateSection: View {
  let updater: Updater

  var body: some View {
    Section("Updates") {
      status
      Button("Check for updates") {
        Task { await updater.check() }
      }
      .disabled(updater.state.isBusy)
      if offersInstall {
        installRow
      }
    }
  }

  @ViewBuilder
  private var status: some View {
    if case .failed(let message) = updater.state {
      ErrorText(message)
    } else {
      ActivityRow(text: updater.state.statusText, isWorking: updater.state.isBusy)
    }
  }

  private var installRow: some View {
    VStack(alignment: .leading, spacing: Metrics.Spacing.tight) {
      HStack(spacing: Metrics.Spacing.comfortable) {
        Button("Install and relaunch") {
          Task { await updater.install() }
        }
        .disabled(updater.state.isBusy)
        if case .available(let release) = updater.state {
          Link("Release notes", destination: release.pageURL)
        }
      }
      CaptionText(
        "macOS asks for Accessibility access again after an update, because each release has a new signature."
      )
    }
  }

  private var offersInstall: Bool {
    if case .available = updater.state { return true }
    return updater.state.isInstalling
  }
}
