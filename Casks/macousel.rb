cask "macousel" do
  version "0.4.2"
  sha256 "323d2991770b31da76a51668b3e70a12a21160d4ecfe4596ca1a414830dd6c5f"

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
