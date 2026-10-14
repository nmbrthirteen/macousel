import SwiftUI

struct SceneWallpaper: View {
  private static let colors: [Color] = [
    Color(red: 0.24, green: 0.29, blue: 0.74), Color(red: 0.30, green: 0.50, blue: 0.95),
    Color(red: 0.56, green: 0.76, blue: 1.00),
    Color(red: 0.44, green: 0.34, blue: 0.84), Color(red: 0.36, green: 0.55, blue: 0.95),
    Color(red: 0.98, green: 0.71, blue: 0.56),
    Color(red: 0.19, green: 0.19, blue: 0.54), Color(red: 0.55, green: 0.40, blue: 0.80),
    Color(red: 0.98, green: 0.56, blue: 0.36),
  ]

  private static let points: [SIMD2<Float>] = [
    [0, 0], [0.5, 0], [1, 0],
    [0, 0.5], [0.42, 0.55], [1, 0.45],
    [0, 1], [0.6, 1], [1, 1],
  ]

  var body: some View {
    MeshGradient(width: 3, height: 3, points: Self.points, colors: Self.colors)
  }
}
