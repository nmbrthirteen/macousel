cask "macousel" do
  version "0.4.4"
  sha256 "8c799c3bff71e3592384382952da2ba59016d5fb3098d61ba530e806567a2eda"

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
