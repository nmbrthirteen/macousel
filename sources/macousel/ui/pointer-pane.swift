import SwiftUI

struct PointerPane: View {
  private static let fingerOptions = [3, 4]

  @Bindable var store: PreferencesStore

  private var gesturesAreOff: Bool {
    !store.preferences.scrollGestureEnabled && !store.preferences.swipeGestureEnabled
  }

  var body: some View {
    SettingsForm {
      PointerPreview(preferences: store.preferences)

      SettingsGroup(title: "Pointer") {
        ToggleRow(
          title: "Activate the display under the pointer",
          isOn: $store.preferences.displayFollowsPointer,
          caption: "Shortcuts act on the display your pointer is on.")
          .engineGated(.displayFollowsPointer, for: store.preferences.engine)
        ToggleRow(title: "Focus follows mouse", isOn: $store.preferences.focusFollowsMouse)
        ToggleRow(title: "Mouse follows focus", isOn: $store.preferences.mouseFollowsFocus)
        if !EngineFeature.dragPreviews.isSupported(by: store.preferences.engine) {
          CaptionedRow(caption: EngineFeature.unsupportedCaption) {
            Text("Drag a window to reorder or stack it")
              .foregroundStyle(.secondary)
          }
        }
      }

      SettingsGroup(title: "Gestures") {
        ToggleRow(
          title: "Scroll gesture", isOn: $store.preferences.scrollGestureEnabled,
          caption: "Hold ⌃⌥ and scroll with two fingers to move the strip.")
        ToggleRow(
          title: "Trackpad swipe", isOn: $store.preferences.swipeGestureEnabled,
          caption: "macOS also uses this swipe for Spaces. Change that in System Settings > Trackpad.")
        Picker("Swipe fingers", selection: $store.preferences.swipeFingers) {
          ForEach(Self.fingerOptions, id: \.self) { count in
            Text("\(count) fingers").tag(count)
          }
        }
        .disabled(!store.preferences.swipeGestureEnabled)
        LabelledSliderRow(
          title: "Swipe sensitivity", value: $store.preferences.swipeSensitivity,
          range: Preferences.swipeSensitivityRange, step: 0.1, readout: .multiplier)
          .disabled(!store.preferences.swipeGestureEnabled)
        ToggleRow(
          title: "Reverse direction", isOn: $store.preferences.reversesSwipeDirection,
          caption: "Applies to the trackpad swipe and the scroll gesture.")
          .disabled(gesturesAreOff)
      }
    }
  }
}
