cask "macousel" do
  version "0.4.3"
  sha256 "c16c18dc445ec8539fb53b26f68b996619223b47e3f0de1c1807ef3ac6137453"

  url "https://github.com/nmbrthirteen/macousel/releases/download/v#{version}/Macousel.dmg"
  name "Macousel"
  desc "Scrolling window manager"
  homepage "https://github.com/nmbrthirteen/macousel"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Macousel.app"

  zap trash: [
    "~/Library/Application Support/Macousel",
    "~/Library/Logs/Macousel",
    "~/Library/Preferences/dev.macousel.app.plist",
  ]

  caveats <<~EOS
    Macousel is not notarized. On first launch, open System Settings >
    Privacy & Security and click "Open Anyway". Then allow Accessibility
    access when macOS asks.
  EOS
end
