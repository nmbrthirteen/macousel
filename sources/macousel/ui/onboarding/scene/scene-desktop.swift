import SwiftUI

struct SceneDesktop: View {
  let pose: ScenePose

  var body: some View {
    ZStack(alignment: .topLeading) {
      SceneWallpaper()
      stage
        .opacity(pose.stage)
      SceneMenuBar(position: pose.position, highlight: pose.menu)
      if pose.menu > 0 {
        SceneMenu(visibility: pose.menu, highlighted: pose.menuHighlight)
      }
      if let point = pose.cursor, pose.cursorVisibility > 0 {
        SceneCursorView(point: point, press: pose.press)
          .opacity(pose.cursorVisibility * pose.stage)
      }
    }
    .frame(width: OnboardingSceneMetrics.size.width, height: OnboardingSceneMetrics.size.height)
    .clipped()
  }

  private var stage: some View {
    ZStack(alignment: .topLeading) {
      ForEach(pose.windows) { SceneWindowView(window: $0) }
      if pose.card > 0 {
        SceneAccessCard(visibility: pose.card, toggle: pose.toggle).zIndex(2)
      }
      if let keys = pose.keys, pose.keysVisibility > 0 {
        SceneKeyOverlay(keys: keys, visibility: pose.keysVisibility).zIndex(3)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
