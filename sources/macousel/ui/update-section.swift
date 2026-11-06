import SwiftUI

struct UpdateSection: View {
  let updater: Updater

  var body: some View {
    SettingsGroup(title: "Updates") {
      LabeledContent {
        Button("Check for updates") {
          Task(priority: .utility) { await updater.check() }
        }
        .disabled(updater.state.isBusy)
      } label: {
        status
      }
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
    LabeledContent {
      HStack(spacing: Metrics.Spacing.comfortable) {
        if case .available(let release) = updater.state, let notes = release.notesPageURL {
          Link("Release notes", destination: notes)
        }
        Button("Install and relaunch") {
          Task { await updater.install() }
        }
        .disabled(updater.state.isBusy)
      }
    } label: {
      RowLabel(
        title: "Update",
        detail:
          "macOS asks for Accessibility access again after an update. Each release has a new signature.")
    }
  }

  private var offersInstall: Bool {
    if case .available = updater.state { return true }
    return updater.state.isInstalling
  }
}
