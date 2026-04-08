cask "firefoo" do
  arch arm: "arm64", intel: "x64"

  version "1.5.11"
  sha256 arm:   "e5ac6c63b51a67a566ac7f745295d8d99b30c89296720da4ff15ad3d65201c92",
         intel: "312a1fa97a5edbfbe7d6dadf751c0e695da767a18912712f8859092ce2ce9de0"

  url "https://github.com/mltek/firefoo-releases/releases/download/v#{version}/Firefoo-#{version}-#{arch}.dmg",
      verified: "github.com/mltek/firefoo-releases/"
  name "Firefoo"
  desc "GUI client for Firebase Firestore"
  homepage "https://www.firefoo.com/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :big_sur"

  app "Firefoo.app"

  uninstall quit: "com.electron.firefoo"

  zap trash: [
    "~/Library/Application Support/Firefoo",
    "~/Library/Logs/Firefoo",
    "~/Library/Preferences/com.electron.firefoo.plist",
  ]
end
