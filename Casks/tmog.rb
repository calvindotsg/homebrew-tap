cask "tmog" do
  version "0.1.3,20260906032818"
  sha256 "aca8fefeb80288eff67bc926565c8d9ae6f02525bc8fb189f8995eeef5d1a271"

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
