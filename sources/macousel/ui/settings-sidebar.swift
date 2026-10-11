import SwiftUI

struct SettingsSidebar: View {
  @Binding var selection: SettingsSection
  let query: String

  var body: some View {
    List(selection: $selection) {
      ForEach(SettingsSectionGroup.allCases, id: \.self) { group in
        groupRows(group)
      }
    }
    .listStyle(.sidebar)
    .overlay {
      if SettingsSection.matching(query).isEmpty {
        ContentUnavailableView.search(text: query)
      }
    }
  }

  @ViewBuilder
  private func groupRows(_ group: SettingsSectionGroup) -> some View {
    let sections = group.sections(matching: query)
    if let title = group.title {
      if !sections.isEmpty {
        Section(title) { rows(sections) }
      }
    } else {
      rows(sections)
    }
  }

  private func rows(_ sections: [SettingsSection]) -> some View {
    ForEach(sections) { section in
      Label {
        Text(section.title)
      } icon: {
        SidebarIconTile(systemImage: section.systemImage, tint: section.tint)
      }
      .tag(section)
    }
  }
}
