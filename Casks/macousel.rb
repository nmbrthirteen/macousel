cask "macousel" do
  version "0.1.6"
  sha256 "34bb50b5f46471b9e28ba6b831a8c1e8b608bbb17483d9a755e361999e73a5ef"

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
