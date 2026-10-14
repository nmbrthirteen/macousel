cask "macousel" do
  version "0.2.10"
  sha256 "0cc6681e3fa14abf653e65df2ffcd88f08861a4c7994b48a2ec40a0baa024f48"

  url "https://github.com/nmbrthirteen/macousel/releases/download/v#{version}/Macousel.dmg"
  name "Macousel"
  desc "Scrolling window manager"
  homepage "https://github.com/nmbrthirteen/macousel"

  depends_on arch: :arm64
  depends_on macos: :tahoe

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
