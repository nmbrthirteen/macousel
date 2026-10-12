cask "macousel" do
  version "0.2.5"
  sha256 "ebfbf06dfcf41f03358218666c95e0fc6a61da0181b737dbe0936becba576949"

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
