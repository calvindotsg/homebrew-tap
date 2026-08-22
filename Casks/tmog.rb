cask "tmog" do
  version "0.1.1,20260821200548"
  sha256 "11f7e6a5d44a1590e0a9fcaa20b0936e7b0f6c029e14f7a888f0b3a7a5c88fe0"

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

  depends_on macos: :ventura

  app "Task Manager TMOG.app"

  uninstall quit: "com.tmog.taskmanager"

  zap trash: [
    "~/Library/Caches/com.tmog.taskmanager",
    "~/Library/HTTPStorages/com.tmog.taskmanager",
    "~/Library/Preferences/com.tmog.taskmanager.plist",
    "~/Library/Saved Application State/com.tmog.taskmanager.savedState",
  ]
end
