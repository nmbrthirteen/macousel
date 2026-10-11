import SwiftUI

struct OverviewCardView: View {
  let card: OverviewGeometry.Card
  let icon: NSImage?
  var isLifted = false

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: Metrics.Radius.panel)
  }

  private var isRoomy: Bool { card.rect.height >= Metrics.Overview.roomyCardMinimumHeight }
  private var showsTitle: Bool { card.rect.width >= Metrics.Overview.titleMinimumWidth }
  private var showsBadge: Bool { card.rect.width >= Metrics.Overview.badgeMinimumWidth }

  var body: some View {
    Group {
      if isRoomy { roomyContent } else { compactContent }
    }
    .padding(Metrics.Spacing.regular)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlaySurface(in: shape)
    .overlay {
      if card.isSelected {
        shape.strokeBorder(Color.accentColor, lineWidth: Metrics.Overview.selectionStroke)
      }
    }
    .opacity(isLifted ? Metrics.Overview.liftOpacity : 1)
    .scaleEffect(isLifted ? Metrics.Overview.liftScale : 1)
    .shadow(
      color: .black.opacity(isLifted ? Metrics.Overview.liftShadowOpacity : 0),
      radius: Metrics.Overview.liftShadowRadius, y: Metrics.Spacing.compact)
    .contentShape(shape)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(card.content.title)
    .accessibilityAddTraits(card.isSelected ? [.isButton, .isSelected] : .isButton)
  }

  private var roomyContent: some View {
    ZStack(alignment: .topLeading) {
      VStack(spacing: Metrics.Spacing.regular) {
        appIcon(side: Metrics.Overview.iconSide)
        if showsTitle { title(alignment: .center) }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      badge
    }
  }

  private var compactContent: some View {
    HStack(spacing: Metrics.Spacing.compact) {
      appIcon(side: Metrics.Overview.compactIconSide)
      if showsTitle { title(alignment: .leading) }
      Spacer(minLength: 0)
      badge
    }
  }

  @ViewBuilder
  private var badge: some View {
    if let number = card.number, showsBadge {
      Text("\(number)")
        .font(.caption.weight(.semibold).monospacedDigit())
        .padding(.horizontal, Metrics.Spacing.compact)
        .padding(.vertical, Metrics.Spacing.hairline)
        .background(Color.primary.opacity(Metrics.Opacity.overviewBadge), in: Capsule())
    }
  }

  @ViewBuilder
  private func appIcon(side: Double) -> some View {
    if let icon {
      Image(nsImage: icon).resizable().interpolation(.high).frame(width: side, height: side)
    } else {
      Image(systemName: "macwindow").resizable().scaledToFit().frame(width: side, height: side)
        .foregroundStyle(.secondary)
    }
  }

  private func title(alignment: TextAlignment) -> some View {
    Text(card.content.title)
      .font(.callout)
      .lineLimit(alignment == .center ? Metrics.Overview.titleLineLimit : 1)
      .multilineTextAlignment(alignment)
      .truncationMode(.tail)
  }
}
