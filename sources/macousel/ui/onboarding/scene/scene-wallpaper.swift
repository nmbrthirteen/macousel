import SwiftUI

struct SceneWallpaper: View {
  // System blue keeps the white menu bar legible whatever accent color people pick.
  var body: some View {
    Rectangle().fill(Color.blue.gradient)
  }
}
