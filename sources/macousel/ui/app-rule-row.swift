import SwiftUI

struct AppRuleRow: View {
  private static let slotRange = 1...9

  @Binding var rule: AppRule
  private let identity: AppIdentity
  private let onRemove: () -> Void

  init(rule: Binding<AppRule>, onRemove: @escaping () -> Void) {
    _rule = rule
    identity = AppIdentity(bundleIdentifier: rule.wrappedValue.bundleIdentifier)
    self.onRemove = onRemove
  }

  var body: some View {
    LabeledContent {
      HStack {
        Picker("Behavior", selection: kind) {
          ForEach(AppRuleKind.allCases, id: \.self) { option in
            Text(option.title).tag(option)
          }
        }
        .labelsHidden()
        .fixedSize()
        switch rule.behavior {
        case .float:
          EmptyView()
        case .width:
          PercentPicker(title: "Width", selection: width)
            .labelsHidden()
            .fixedSize()
        case .slot:
          Stepper("Slot \(slot.wrappedValue)", value: slot, in: Self.slotRange)
            .fixedSize()
        }
        RemoveButton(label: "Remove \(identity.name)", action: onRemove)
      }
    } label: {
      AppLabel(identity: identity)
    }
  }

  private var kind: Binding<AppRuleKind> {
    Binding(
      get: { AppRuleKind(rule.behavior) },
      set: { rule.behavior = $0.defaultBehavior }
    )
  }

  private var width: Binding<Double> {
    Binding(
      get: {
        if case .width(let fraction) = rule.behavior { return fraction }
        return AppRuleKind.defaultWidth
      },
      set: { rule.behavior = .width($0) }
    )
  }

  private var slot: Binding<Int> {
    Binding(
      get: {
        if case .slot(let position) = rule.behavior { return position }
        return AppRuleKind.defaultSlot
      },
      set: { rule.behavior = .slot($0) }
    )
  }
}
