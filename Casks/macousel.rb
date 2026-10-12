cask "macousel" do
  version "0.2.2"
  sha256 "23321a9fde9cd5c607d272093dc8a4e01fed3ce6edb2c71e02aac710858b5d89"

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
