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
        Picker("Rule for \(identity.name)", selection: kind) {
          ForEach(AppRuleKind.allCases, id: \.self) { option in
            Text(option.title).tag(option)
          }
        }
        .labelsHidden()
        .frame(width: SettingsMetrics.ruleKindWidth, alignment: .trailing)
        value
          .frame(width: SettingsMetrics.ruleValueWidth, alignment: .trailing)
        RemoveButton(label: "Remove rule for \(identity.name)", action: onRemove)
      }
    } label: {
      AppLabel(identity: identity)
    }
  }

  @ViewBuilder
  private var value: some View {
    switch rule.behavior {
    case .float:
      EmptyView()
    case .width:
      PercentPicker(title: "Width for \(identity.name)", selection: width)
        .labelsHidden()
        .fixedSize()
    case .slot:
      HStack(spacing: Metrics.Spacing.regular) {
        Text("\(slot.wrappedValue)")
          .monospacedDigit()
        Stepper("Column for \(identity.name)", value: slot, in: Self.slotRange)
          .labelsHidden()
      }
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
