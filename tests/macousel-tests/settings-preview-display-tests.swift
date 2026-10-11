import CoreGraphics
import Testing
import WindowSystem

@testable import Macousel

@MainActor
struct SettingsPreviewDisplayTests {
  private static let container = CGSize(width: 500, height: 150)

  private func geometry(_ displays: [Display], disabled: Set<String> = []) -> DisplayDrawingGeometry {
    DisplayDrawingGeometry(displays: displays, disabled: disabled, container: Self.container)
  }

  @Test func noDisplaysDrawNothing() {
    #expect(geometry([]).items.isEmpty)
  }

  @Test func oneDisplayIsCentred() throws {
    let result = geometry([.fake()])
    let item = try #require(result.items.first)
    #expect(abs(item.screenRect.midX - 250) < 0.001)
    #expect(abs(item.screenRect.midY - 75) < 0.001)
    #expect(abs(item.screenRect.width / item.screenRect.height - 1000.0 / 800.0) < 0.001)
  }

  @Test func twoDisplaysSideBySideKeepTheirProportionsAndPositions() throws {
    let result = geometry([.leftOfPair, .rightOfPair])
    let left = try #require(result.items.first)
    let right = try #require(result.items.last)
    #expect(abs(left.screenRect.width - right.screenRect.width) < 0.001)
    #expect(abs(left.screenRect.maxX - right.screenRect.minX) < 0.001)
    #expect(abs(left.screenRect.minY - right.screenRect.minY) < 0.001)
    #expect(abs(right.screenRect.minX - left.screenRect.minX - 1000 * result.scale) < 0.001)
    #expect(abs((left.screenRect.minX + right.screenRect.maxX) / 2 - 250) < 0.001)
  }

  @Test func differentlySizedDisplaysShareOneScale() throws {
    let wide = Display.fake(id: 1, width: 2000, height: 1000)
    let small = Display.fake(id: 2, originX: 2000, width: 1000, height: 1000)
    let result = geometry([wide, small])
    let first = try #require(result.items.first)
    let second = try #require(result.items.last)
    #expect(abs(first.screenRect.width / second.screenRect.width - 2) < 0.001)
    #expect(abs(first.screenRect.height - second.screenRect.height) < 0.001)
  }

  @Test func displaysFitInsideTheContainerWithTheirInsets() throws {
    let result = geometry([.leftOfPair, .rightOfPair])
    let bounds = CGRect(origin: .zero, size: Self.container)
    #expect(result.items.allSatisfy { bounds.contains($0.screenRect) })
  }

  @Test func switchedOffDisplayIsNotTiled() throws {
    let result = geometry([.leftOfPair, .rightOfPair], disabled: [Display.rightOfPair.uuid])
    #expect(result.items.map(\.isTiled) == [true, false])
  }

  @Test func itemsAreLabelledWithTheDisplayName() {
    let result = geometry([.leftOfPair, .rightOfPair])
    #expect(result.items.map(\.name) == ["Display 1", "Display 2"])
  }

  @Test func labelBandSitsBelowTheContentInsideTheScreen() throws {
    let item = try #require(geometry([.fake()]).items.first)
    #expect(item.labelRect.minY >= item.contentRect.maxY - 0.001)
    #expect(item.screenRect.contains(item.labelRect))
    #expect(item.screenRect.contains(item.contentRect))
  }

  @Test func descriptionNamesEachDisplayAndItsTilingState() {
    let text = PreviewDescription.displays(
      [.leftOfPair, .rightOfPair], disabled: [Display.rightOfPair.uuid])
    #expect(text == "Preview: 2 displays, Display 1 tiled, Display 2 not tiled")
    #expect(PreviewDescription.displays([.fake()], disabled: []).contains("1 display,"))
  }
}
