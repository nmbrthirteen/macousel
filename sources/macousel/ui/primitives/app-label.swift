import SwiftUI

struct AppLabel: View {
  let identity: AppIdentity

  init(identity: AppIdentity) {
    self.identity = identity
  }

  init(bundleIdentifier: String) {
    identity = AppIdentity(bundleIdentifier: bundleIdentifier)
  }

  var body: some View {
    Label {
      Text(identity.name)
    } icon: {
      Image(nsImage: identity.icon)
    }
  }
}
