import SwiftUI

struct OverviewCardView: View {
  let card: OverviewGeometry.Card
  let icon: NSImage?
  let previews: OverviewPreviews
  let radius: Double
  var isLifted = false
  var isHovered = false

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: radius, style: .continuous)
  }

  private var isRoomy: Bool { card.rect.height >= Metrics.Overview.roomyCardMinimumHeight }
  private var showsTitle: Bool { card.rect.width >= Metrics.Overview.titleMinimumWidth }
  private var showsBadge: Bool { card.rect.width >= Metrics.Overview.badgeMinimumWidth }

  private var restingScale: Double {
    if isHovered { return OverlayTiming.overviewHoverScale }
    return card.isSelected ? OverlayTiming.overviewSelectedScale : 1
  }

  var body: some View {
    let picture = previews.images[card.id]
    ZStack {
      if let picture {
        Image(decorative: picture, scale: 1)
          .resizable()
          .interpolation(.high)
          .aspectRatio(contentMode: .fill)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipShape(shape)
          .overlay(alignment: .topLeading) {
            badge(onPicture: true).padding(Metrics.Spacing.regular)
          }
          .transition(.opacity)
      } else {
        placeholder.transition(.opacity)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay {
      shape.strokeBorder(
        Color.white.opacity(Metrics.Opacity.overviewHairline),
        lineWidth: Metrics.Size.hairlineStroke)
    }
    .overlay {
      if card.isSelected {
        shape.strokeBorder(Color.accentColor, lineWidth: Metrics.Overview.selectionStroke)
      }
    }
    .shadow(
      color: .black.opacity(
        card.isSelected
          ? Metrics.Opacity.overviewSelectedShadow : Metrics.Opacity.overviewCardShadow),
      radius: card.isSelected
        ? Metrics.Overview.selectedShadowRadius : Metrics.Overview.cardShadowRadius,
      y: Metrics.Overview.cardShadowOffset)
    .scaleEffect(restingScale)
    .opacity(isLifted ? Metrics.Overview.liftOpacity : 1)
    .overlayLift(
      isLifted, scale: OverlayTiming.liftScale, shadowRadius: Metrics.Overview.liftShadowRadius)
    .overlay(alignment: .bottom) {
      if isHovered { hoverTitle }
    }
    .animation(
      .spring(
        response: OverlayTiming.overviewHoverResponse,
        dampingFraction: OverlayTiming.criticalDamping),
      value: isHovered
    )
    .contentShape(shape)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(card.content.title)
    .accessibilityAddTraits(card.isSelected ? [.isButton, .isSelected] : .isButton)
  }

  private var placeholder: some View {
    Group {
      if isRoomy { roomyContent } else { compactContent }
    }
    .padding(Metrics.Spacing.regular)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlaySurface(in: shape)
  }

  private var roomyContent: some View {
    ZStack(alignment: .topLeading) {
      VStack(spacing: Metrics.Spacing.regular) {
        appIcon(side: Metrics.Overview.iconSide)
        if showsTitle { title(alignment: .center) }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      badge(onPicture: false)
    }
  }

  private var compactContent: some View {
    HStack(spacing: Metrics.Spacing.compact) {
      appIcon(side: Metrics.Overview.compactIconSide)
      if showsTitle { title(alignment: .leading) }
      Spacer(minLength: 0)
      badge(onPicture: false)
    }
  }

  private var hoverTitle: some View {
    let gap = Metrics.Overview.hoverTitleGap
    return Text(card.content.title)
      .font(.overlay(.regular, weight: .medium))
      .lineLimit(1)
      .truncationMode(.middle)
      .padding(.horizontal, Metrics.Spacing.comfortable)
      .padding(.vertical, Metrics.Spacing.tight)
      .overlaySurface(in: Capsule())
      .frame(width: Metrics.Overview.hoverTitleMaximumWidth)
      .fixedSize()
      .alignmentGuide(.bottom) { $0[.top] - gap }
      .allowsHitTesting(false)
      .transition(.opacity)
  }

  @ViewBuilder
  private func badge(onPicture: Bool) -> some View {
    if let number = card.number, showsBadge {
      Text("\(number)")
        .font(.overlay(.small, weight: .semibold))
        .padding(.horizontal, Metrics.Spacing.compact)
        .padding(.vertical, Metrics.Spacing.hairline)
        .background(
          onPicture
            ? AnyShapeStyle(.regularMaterial)
            : AnyShapeStyle(Color.primary.opacity(Metrics.Opacity.overviewBadge)),
          in: Capsule())
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
      .font(.overlay(.regular))
      .lineLimit(alignment == .center ? Metrics.Overview.titleLineLimit : 1)
      .multilineTextAlignment(alignment)
      .truncationMode(.middle)
  }
}
