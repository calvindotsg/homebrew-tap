cask "tmog" do
  version "0.1.4,20260916001402"
  sha256 "b89aa98f75303dd5a21cdf1be491ccfc956c650051d1c2bb3e6882eaf6e08d57"

  url "https://www.tmog.org/downloads/TMOG-Task-Manager-#{version.csv.first}-#{version.csv.second}-macOS-universal.dmg"
  name "Task Manager TMOG"
  desc "Native system monitor for CPU, memory, storage, network, and thermals"
  homepage "https://www.tmog.org/"

  livecheck do
    url "https://www.tmog.org/downloads/release.json"
    strategy :json do |json|
      next if json["version"].blank?

      json["build"].present? ? "#{json["version"]},#{json["build"]}" : json["version"]
    end
  end

  depends_on macos: :sonoma

  app "Task Manager TMOG.app"

  uninstall quit: "com.tmog.taskmanager"

  zap trash: [
    "~/Library/Caches/com.tmog.taskmanager",
    "~/Library/HTTPStorages/com.tmog.taskmanager",
    "~/Library/Preferences/com.tmog.taskmanager.plist",
    "~/Library/Saved Application State/com.tmog.taskmanager.savedState",
  ]
end
