cask "macousel" do
  version "0.1.11"
  sha256 "bd0584bb2143795902fd4326125fc5d497be3303ab181b25b2075d2c12f28d19"

  url "https://github.com/nmbrthirteen/macousel/releases/download/v#{version}/Macousel.dmg"
  name "Macousel"
  desc "Scrolling window manager"
  homepage "https://github.com/nmbrthirteen/macousel"

  depends_on arch: :arm64
  depends_on macos: :tahoe

  app "Macousel.app"

  zap trash: "~/Library/Preferences/dev.macousel.app.plist"

  caveats <<~EOS
    Macousel is not notarized. On first launch, open System Settings >
    Privacy & Security and click "Open Anyway". Then allow Accessibility
    access when macOS asks.
  EOS
end
