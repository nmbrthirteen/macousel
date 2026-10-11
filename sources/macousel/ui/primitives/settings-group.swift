import SwiftUI

struct SettingsGroup<Content: View>: View {
  let title: String
  var footer: String?
  @ViewBuilder let content: Content

  var body: some View {
    Section {
      content
    } header: {
      Text(title)
    } footer: {
      if let footer {
        CaptionText(footer)
      }
    }
  }
}
