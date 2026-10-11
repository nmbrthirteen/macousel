import StripCore
import SwiftUI

struct LayoutPane: View {
  private static let gapRange = 0.0...40.0

  @Bindable var store: PreferencesStore
  @State private var hoveredPreset: Double?

  var body: some View {
    SettingsForm {
      LayoutPreview(
        config: store.preferences.layout, animationSpeed: store.preferences.animationSpeed,
        hoveredPreset: hoveredPreset)

      Section("Gaps") {
        LabelledSliderRow(
          title: "Gap between windows", value: $store.preferences.layout.innerGap,
          range: Self.gapRange, step: 1, readout: .points)
        LabelledSliderRow(
          title: "Gap at screen edges", value: $store.preferences.layout.outerGap,
          range: Self.gapRange, step: 1, readout: .points)
      }

      Section("Widths") {
        PercentPicker(
          title: "Default width of new windows",
          selection: $store.preferences.layout.defaultWidth)
        Picker("Center the focused column", selection: $store.preferences.layout.centerMode) {
          ForEach(CenterMode.allCases, id: \.self) { mode in
            Text(mode.title).tag(mode)
          }
        }
        CaptionText(store.preferences.layout.centerMode.summary)
        PresetWidthsEditor(
          widths: $store.preferences.layout.presetWidths, hoveredWidth: $hoveredPreset)
      }
    }
  }
}
