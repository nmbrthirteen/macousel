import SwiftUI

struct DisplaysPane: View {
  @Bindable var store: PreferencesStore
  let manager: WindowManager

  var body: some View {
    if manager.displays.isEmpty {
      ContentUnavailableView(
        "No displays found", systemImage: "display",
        description: Text("Displays appear here after you allow Accessibility access."))
    } else {
      SettingsForm {
        SettingsGroup(title: "Tiling") {
          DisplaysPreview(
            displays: manager.displays, disabled: store.preferences.disabledDisplays,
            config: store.preferences.layout, animationSpeed: store.preferences.animationSpeed)
          ForEach(manager.displays, id: \.uuid) { display in
            ToggleRow(
              title: "Tile windows on \(display.name)", isOn: tilingBinding(for: display.uuid),
              unavailable: EngineFeature.perDisplayTiling.unavailableCaption(
                for: store.preferences.engine))
          }
        }
      }
    }
  }

  private func tilingBinding(for uuid: String) -> Binding<Bool> {
    Binding(
      get: { !store.preferences.disabledDisplays.contains(uuid) },
      set: { isOn in
        if isOn {
          store.preferences.disabledDisplays.remove(uuid)
        } else {
          store.preferences.disabledDisplays.insert(uuid)
        }
      }
    )
  }
}
