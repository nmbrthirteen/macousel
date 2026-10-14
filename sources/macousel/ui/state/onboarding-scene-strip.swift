import CoreGraphics

struct SceneStrip: Equatable {
  struct Column: Equatable {
    let window: Int
    let style: SceneWindowStyle
    var widthShare: Double
  }

  private typealias Scene = OnboardingSceneMetrics

  var columns: [Column]
  private(set) var focused: Int
  private(set) var offset = 0.0
  var isOverview = false

  init(styles: [SceneWindowStyle], widthShares: [Double], focused: Int = 0) {
    columns = zip(styles.indices, zip(styles, widthShares)).map { index, pair in
      Column(window: index, style: pair.0, widthShare: pair.1)
    }
    self.focused = focused
    reveal(focused)
  }

  mutating func focus(_ index: Int) {
    guard columns.indices.contains(index) else { return }
    focused = index
    reveal(index)
  }

  mutating func moveFocused(by step: Int) {
    let target = focused + step
    guard columns.indices.contains(target) else { return }
    columns.swapAt(focused, target)
    focus(target)
  }

  mutating func setFocusedWidth(_ share: Double) {
    columns[focused].widthShare = share
    reveal(focused)
  }

  var position: StripPosition {
    StripPosition(
      pages: columns.map { StripPosition.Page(widthShare: $0.widthShare, rowCount: 1) },
      focusedIndex: focused)
  }

  var windows: [SceneWindow] {
    let lefts = columnLefts
    let rects = columns.indices.map { index in
      CGRect(
        x: lefts[index] - offset, y: Scene.windowTop,
        width: width(of: index), height: Scene.windowHeight)
    }
    let placed = isOverview ? overview(rects) : rects
    return columns.indices.map { index in
      SceneWindow(
        id: columns[index].window, style: columns[index].style, rect: placed[index],
        isFocused: index == focused)
    }
  }

  private func width(of index: Int) -> Double {
    Scene.usableWidth * columns[index].widthShare - Scene.columnGap / 2
  }

  private var columnLefts: [Double] {
    columns.indices.reduce(into: [Double]()) { lefts, index in
      lefts.append(lefts.last.map { $0 + width(of: index - 1) + Scene.columnGap } ?? Scene.edgeGap)
    }
  }

  private mutating func reveal(_ index: Int) {
    let left = columnLefts[index] - Scene.edgeGap
    let right = columnLefts[index] + width(of: index) + Scene.edgeGap - Scene.size.width
    offset = min(max(offset, right), left)
  }

  private func overview(_ rects: [CGRect]) -> [CGRect] {
    guard let first = rects.first, let last = rects.last else { return rects }
    let span = last.maxX - first.minX
    let scale = min(1, Scene.usableWidth / span) * Scene.overviewScale
    let center = CGPoint(x: Scene.size.width / 2, y: Scene.windowTop + Scene.windowHeight / 2)
    let middle = (first.minX + last.maxX) / 2
    return rects.map { rect in
      CGRect(
        x: center.x + (rect.minX - middle) * scale,
        y: center.y - rect.height * scale / 2,
        width: rect.width * scale, height: rect.height * scale)
    }
  }
}
