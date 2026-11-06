import StripCore

enum MinimapLabel {
  static func text(
    for window: WindowID?, in snapshot: MinimapSnapshot, appName: (String) -> String
  ) -> String? {
    guard let window,
      let column = snapshot.columns.firstIndex(where: { $0.rows.contains { $0.window == window } })
    else { return nil }
    let row = snapshot.columns[column].rows.first { $0.window == window }
    return row?.bundleIdentifier.map(appName) ?? "Column \(column + 1)"
  }
}
