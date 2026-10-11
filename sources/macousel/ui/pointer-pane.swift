import SwiftUI

struct PointerPane: View {
  private static let fingerOptions = [3, 4]

  @Bindable var store: PreferencesStore

  var body: some View {
    SettingsForm {
      PointerPreview(preferences: store.preferences)

      Section("Pointer") {
        ToggleRow(
          title: "Activate the display under the pointer",
          isOn: $store.preferences.displayFollowsPointer,
          caption: "Shortcuts act on the display your pointer is on.")
        ToggleRow(title: "Focus follows mouse", isOn: $store.preferences.focusFollowsMouse)
        ToggleRow(title: "Mouse follows focus", isOn: $store.preferences.mouseFollowsFocus)
      }

      Section("Gestures") {
        ToggleRow(
          title: "Scroll gesture", isOn: $store.preferences.scrollGestureEnabled,
          caption: "Hold ⌃⌥ and scroll with two fingers to move the strip.")
        ToggleRow(
          title: "Trackpad swipe", isOn: $store.preferences.swipeGestureEnabled,
          caption:
            "macOS uses the same swipe to switch desktops. Set the other finger count in System Settings > Trackpad > More Gestures."
        )
        Picker("Swipe fingers", selection: $store.preferences.swipeFingers) {
          ForEach(Self.fingerOptions, id: \.self) { count in
            Text("\(count) fingers").tag(count)
          }
        }
        .pickerStyle(.segmented)
        .disabled(!store.preferences.swipeGestureEnabled)
        LabelledSliderRow(
          title: "Swipe sensitivity", value: $store.preferences.swipeSensitivity,
          range: Preferences.swipeSensitivityRange, step: 0.1, readout: .multiplier)
          .disabled(!store.preferences.swipeGestureEnabled)
        ToggleRow(
          title: "Reverse swipe direction", isOn: $store.preferences.reversesSwipeDirection,
          caption: "Applies to the trackpad swipe and the scroll gesture.")
      }
    }
  }
}
