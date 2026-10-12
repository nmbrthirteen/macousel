import SwiftUI

struct MotionPane: View {
  private static let dimRange = 0.05...0.6
  private static let borderWidthRange = 1.0...8.0

  @Bindable var store: PreferencesStore

  var body: some View {
    SettingsForm {
      MotionPreview(preferences: store.preferences)

      SettingsGroup(
        title: "Animation", footer: "Animations follow Reduce Motion and Low Power Mode."
      ) {
        Picker("Animation speed", selection: $store.preferences.animationSpeed) {
          ForEach(AnimationSpeed.allCases, id: \.self) { speed in
            Text(speed.title).tag(speed)
          }
        }
      }

      SettingsGroup(title: "Focus") {
        ToggleRow(title: "Show focus border", isOn: $store.preferences.showsFocusBorder)
        LabelledSliderRow(
          title: "Border width", value: $store.preferences.focusBorderWidth,
          range: Self.borderWidthRange, step: 1, readout: .points)
          .disabled(!store.preferences.showsFocusBorder)
        ToggleRow(title: "Dim inactive windows", isOn: $store.preferences.dimsInactiveWindows)
        LabelledSliderRow(
          title: "Dim amount", value: $store.preferences.dimAmount,
          range: Self.dimRange, step: 0.05, readout: .percent)
          .disabled(!store.preferences.dimsInactiveWindows)
      }

      SettingsGroup(title: "Minimap") {
        ToggleRow(title: "Show strip minimap", isOn: $store.preferences.showsMinimap)
        MinimapPreview(config: store.preferences.layout, isEnabled: store.preferences.showsMinimap)
      }

      SettingsGroup(title: "Menu Bar") {
        Picker("Menu bar shows", selection: $store.preferences.menuBarIndicator) {
          ForEach(MenuBarIndicator.allCases, id: \.self) { indicator in
            Text(indicator.title).tag(indicator)
          }
        }
        MenuBarVariantsPreview(selection: store.preferences.menuBarIndicator)
      }
    }
  }
}
