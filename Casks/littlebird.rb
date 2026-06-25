cask "littlebird" do
  arch arm: "arm64", intel: "x64"

  version "0.80.20"
  sha256 arm:   "58ce203258138193b7aeb54311fdfe3c6c5c16ab01ac9afa62c2172d235d4917",
         intel: "e26067dcb1bdfd6d7cf889e9290b7617c8b6d679b9b25c6dc19fb7d6de7dec8e"

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
    "~/Library/Application Support/Littlebird",
    "~/Library/Caches/@littlebirddesktop-updater",
    "~/Library/Caches/com.genos.littlebird",
    "~/Library/Caches/com.genos.littlebird.ShipIt",
    "~/Library/HTTPStorages/com.genos.littlebird",
    "~/Library/Logs/Littlebird",
    "~/Library/Preferences/com.genos.littlebird.plist",
    "~/Library/Saved Application State/com.genos.littlebird.savedState",
  ]
end
