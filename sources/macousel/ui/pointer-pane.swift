import SwiftUI

struct PointerPane: View {
  @Bindable var store: PreferencesStore

  private var gesturesAreOff: Bool {
    !store.preferences.scrollGestureEnabled && !store.preferences.swipeGestureEnabled
  }

  private var engine: WindowEngine { store.preferences.engine }

  var body: some View {
    SettingsForm {
      SettingsGroup(title: "Pointer") {
        ToggleRow(
          title: "Activate the display under the pointer",
          isOn: $store.preferences.displayFollowsPointer,
          detail: "Shortcuts act on the display your pointer is on.",
          unavailable: EngineFeature.displayFollowsPointer.unavailableCaption(for: engine))
        ToggleRow(title: "Focus follows mouse", isOn: $store.preferences.focusFollowsMouse)
        ToggleRow(title: "Mouse follows focus", isOn: $store.preferences.mouseFollowsFocus)
        if let caption = EngineFeature.dragPreviews.unavailableCaption(for: engine) {
          LabeledContent {
            EmptyView()
          } label: {
            RowLabel(title: "Drag a window to reorder or stack it", detail: caption)
          }
          .disabled(true)
        }
      }

      SettingsGroup(title: "Gestures") {
        PointerPreview(preferences: store.preferences)
        ToggleRow(
          title: "Scroll gesture", isOn: $store.preferences.scrollGestureEnabled,
          detail: "Hold ⌃⌥ and scroll with two fingers to move the strip.")
        ToggleRow(
          title: "Trackpad swipe", isOn: $store.preferences.swipeGestureEnabled,
          detail: "macOS also uses this swipe for Spaces. Change that in System Settings > Trackpad.")
        SwipeFingersPicker(
          selection: $store.preferences.swipeFingers,
          reversesDirection: store.preferences.reversesSwipeDirection)
          .disabled(!store.preferences.swipeGestureEnabled)
        if engine == .paneru {
          Picker("Swipe moves", selection: $store.preferences.swipeStep) {
            ForEach(SwipeStep.allCases, id: \.self) { step in
              Text(step.title).tag(step)
            }
          }
          .disabled(!store.preferences.swipeGestureEnabled)
        }
        LabelledSliderRow(
          title: "Swipe sensitivity", value: $store.preferences.swipeSensitivity,
          range: Preferences.swipeSensitivityRange, step: 0.1, readout: .multiplier)
          .disabled(!store.preferences.swipeGestureEnabled)
        ToggleRow(
          title: "Reverse direction", isOn: $store.preferences.reversesSwipeDirection,
          detail: "Applies to the trackpad swipe and the scroll gesture.")
          .disabled(gesturesAreOff)
      }
    }
  }
}
