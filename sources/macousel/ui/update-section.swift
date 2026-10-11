import SwiftUI

struct UpdateSection: View {
  let updater: Updater

  var body: some View {
    SettingsGroup(title: "Updates") {
      status
      Button("Check for updates") {
        Task(priority: .utility) { await updater.check() }
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
        if case .available(let release) = updater.state, let notes = release.notesPageURL {
          Link("Release notes", destination: notes)
        }
      }
      CaptionText(
        "macOS asks for Accessibility access again after an update. Each release has a new signature."
      )
    }
  }

  private var offersInstall: Bool {
    if case .available = updater.state { return true }
    return updater.state.isInstalling
  }
}
