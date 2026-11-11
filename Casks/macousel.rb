cask "macousel" do
  version "0.4.5"
  sha256 "f5c1b54532cf9a925111ef15126deffb9d5dbb010a9df669da287ecca9f287d1"

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
