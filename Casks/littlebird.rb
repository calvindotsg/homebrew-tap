cask "littlebird" do
  arch arm: "arm64", intel: "x64"

  version "0.84.11"
  sha256 arm:   "31bdbed7b5f64a1ced9b4259dfa3adfd8523401b4c9445af71d754c8212d8790",
         intel: "694d25cd9ab0812864487dfb5cb88a13aa5122d1532d42882be7c540d15d3f46"

  url "https://downloads.lilbirdai.com/#{arch}/Littlebird-Mac-#{arch}-#{version}-Installer.dmg",
      verified: "downloads.lilbirdai.com/"
  name "Littlebird"
  desc "Context-aware AI assistant that reads on-screen text across apps"
  homepage "https://littlebird.ai/"

  livecheck do
    url "https://app.lilbird.co/download/latest?arch=apple"
    strategy :header_match
    regex(/Littlebird-Mac-arm64-(\d+(?:\.\d+)+)-Installer\.dmg/i)
  end

  auto_updates true
  depends_on macos: :ventura

  app "Littlebird.app"

  uninstall launchctl: "com.genos.littlebird.ShipIt",
            quit:      "com.genos.littlebird"

  zap trash: [
    "~/Library/Application Support/@littlebird",
    "~/Library/Application Support/Littlebird",
    "~/Library/Caches/@littlebirddesktop-updater",
    "~/Library/Caches/com.genos.contextkit-cli",
    "~/Library/Caches/com.genos.littlebird",
    "~/Library/Caches/com.genos.littlebird.ShipIt",
    "~/Library/HTTPStorages/com.genos.contextkit-cli",
    "~/Library/HTTPStorages/com.genos.littlebird",
    "~/Library/Logs/@littlebird",
    "~/Library/Logs/Littlebird",
    "~/Library/Preferences/com.genos.littlebird.plist",
    "~/Library/Saved Application State/com.genos.littlebird.savedState",
  ]
end
