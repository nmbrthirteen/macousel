import SwiftUI

struct MotionPane: View {
  private static let dimRange = 0.05...0.6
  private static let borderWidthRange = 1.0...8.0

  @Bindable var store: PreferencesStore

  var body: some View {
    SettingsForm {
      MotionPreview(preferences: store.preferences)

      Section {
        Picker("Animation speed", selection: $store.preferences.animationSpeed) {
          ForEach(AnimationSpeed.allCases, id: \.self) { speed in
            Text(speed.title).tag(speed)
          }
        }
      } footer: {
        CaptionText("Animations follow Reduce Motion and Low Power Mode.")
      }

      Section("Focus and overview") {
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
        ToggleRow(title: "Show strip minimap", isOn: $store.preferences.showsMinimap)
        if store.preferences.showsMinimap {
          MinimapPreview(config: store.preferences.layout)
        }
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
