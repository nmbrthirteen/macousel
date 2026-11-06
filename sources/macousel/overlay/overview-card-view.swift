import SwiftUI

struct OverviewCardView: View {
  let card: OverviewGeometry.Card
  let icon: NSImage?
  let previews: OverviewPreviews
  let radius: Double
  var isLifted = false
  var isHovered = false
  var showsChrome = true

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: radius, style: .continuous)
  }

  private var isRoomy: Bool { card.rect.height >= Metrics.Overview.roomyCardMinimumHeight }
  private var showsTitle: Bool { card.rect.width >= Metrics.Overview.titleMinimumWidth }
  private var showsBadge: Bool { card.rect.width >= Metrics.Overview.badgeMinimumWidth }

  // The picture keeps the window's own transparent corners, so it is never clipped: any clip
  // rounder than the real window would show at the first frame, when it sits on the window.
  var body: some View {
    let picture = previews.images[card.id]
    ZStack {
      if let picture {
        Image(decorative: picture, scale: 1)
          .resizable()
          .interpolation(.high)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
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
      if card.isSelected { focusRing.opacity(showsChrome ? 1 : 0) }
    }
    .opacity(isLifted ? Metrics.Overview.liftOpacity : 1)
    .overlayLift(
      isLifted, scale: OverlayTiming.liftScale, shadowRadius: Metrics.Overview.liftShadowRadius)
    .overlay(alignment: .bottom) {
      if isHovered { hoverTitle }
    }
    .animation(.easeOut(duration: OverlayTiming.fade), value: isHovered)
    .contentShape(shape)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(card.content.title)
    .accessibilityAddTraits(card.isSelected ? [.isButton, .isSelected] : .isButton)
  }

  // Drawn outside the card, in the keyboard focus color, like the system focus ring.
  private var focusRing: some View {
    let width = Metrics.Overview.focusRingWidth
    return RoundedRectangle(cornerRadius: radius + width, style: .continuous)
      .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: width)
      .padding(-width)
      .allowsHitTesting(false)
  }

  private var placeholder: some View {
    Group {
      if isRoomy { roomyContent } else { compactContent }
    }
    .padding(Metrics.Spacing.regular)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.regularMaterial, in: shape)
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
          onPicture ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.quaternary), in: Capsule())
        .opacity(showsChrome ? 1 : 0)
    }
  }

  @ViewBuilder
  private func appIcon(side: Double) -> some View {
    if let icon {
      Image(nsImage: icon).resizable().interpolation(.high).frame(width: side, height: side)
    } else {
      Image(systemName: "macwindow")
        .font(.system(size: side * Metrics.Overview.symbolShare))
        .foregroundStyle(.secondary)
        .frame(width: side, height: side)
    }
  }

  private func title(alignment: TextAlignment) -> some View {
    Text(card.content.title)
      .font(.overlay(.regular))
      .lineLimit(alignment == .center ? Metrics.Overview.titleLineLimit : 1)
      .multilineTextAlignment(alignment)
      .truncationMode(.middle)
      .opacity(showsChrome ? 1 : 0)
  }
}
