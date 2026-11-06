import SwiftUI

struct MotionPane: View {
  private static let dimRange = 0.05...0.6

  @Bindable var store: PreferencesStore

  var body: some View {
    SettingsForm {
      SettingsGroup(title: "Animation") {
        MotionPreview(preferences: store.preferences)
        Picker(selection: $store.preferences.animationSpeed) {
          ForEach(AnimationSpeed.allCases, id: \.self) { speed in
            Text(speed.title).tag(speed)
          }
        } label: {
          RowLabel(
            title: "Animation speed", detail: "Animations follow Reduce Motion and Low Power Mode.")
        }
      }

      SettingsGroup(title: "Focus") {
        ToggleRow(title: "Show focus border", isOn: $store.preferences.showsFocusBorder)
        LabelledSliderRow(
          title: "Border width", value: $store.preferences.focusBorderWidth,
          range: Preferences.focusBorderWidthRange, step: 1, readout: .points)
          .disabled(!store.preferences.showsFocusBorder)
        ToggleRow(title: "Dim inactive windows", isOn: $store.preferences.dimsInactiveWindows)
        LabelledSliderRow(
          title: "Dim amount", value: $store.preferences.dimAmount,
          range: Self.dimRange, step: 0.05, readout: .percent)
          .disabled(!store.preferences.dimsInactiveWindows)
      }

      SettingsGroup(title: "Minimap") {
        MinimapPreview(config: store.preferences.layout, isEnabled: store.preferences.showsMinimap)
        ToggleRow(title: "Show strip minimap", isOn: $store.preferences.showsMinimap)
      }

      SettingsGroup(title: "Menu bar") {
        MenuBarIndicatorPicker(selection: $store.preferences.menuBarIndicator)
      }
    }
  }
}
