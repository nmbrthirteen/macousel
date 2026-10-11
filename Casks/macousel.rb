cask "macousel" do
  version "0.1.7"
  sha256 "999c1712033769677dde6dc8294c42e462c8bd14954e474a45a588321342f3f0"

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
