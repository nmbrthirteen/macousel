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

      SettingsGroup(title: "Gaps") {
        LabelledSliderRow(
          title: "Gap between windows", value: $store.preferences.layout.innerGap,
          range: Self.gapRange, step: 1, readout: .points)
        LabelledSliderRow(
          title: "Gap at screen edges", value: $store.preferences.layout.outerGap,
          range: Self.gapRange, step: 1, readout: .points)
      }

      SettingsGroup(title: "Widths") {
        CaptionedRow(caption: defaultWidthCaption) {
          DefaultWidthPicker(selection: $store.preferences.layout.defaultWidth)
        }
        CaptionedRow(caption: store.preferences.layout.centerMode.summary) {
          CenterModePicker(selection: $store.preferences.layout.centerMode)
        }
      }

      SettingsGroup(
        title: "Preset Widths", footer: "The cycle width shortcut steps through these."
      ) {
        PresetWidthsEditor(
          widths: $store.preferences.layout.presetWidths, hoveredWidth: $hoveredPreset)
      }
    }
  }

  private var defaultWidthCaption: String? {
    store.preferences.engine == .paneru && store.preferences.hasWidthRule
      ? "Paneru ignores this while an app rule sets a width." : nil
  }
}
